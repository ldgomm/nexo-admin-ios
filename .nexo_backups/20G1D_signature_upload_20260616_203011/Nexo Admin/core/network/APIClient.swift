//
//  APIClient.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> Response
    func send<Body: Encodable & Sendable, Response: Decodable & Sendable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response
}

struct APIDataResponse: Sendable {
    let data: Data
    let statusCode: Int
    let headers: [String: String]

    func headerValue(_ name: String) -> String? {
        if let value = headers[name] { return value }

        let lowercasedName = name.lowercased()
        for (key, value) in headers where key.lowercased() == lowercasedName {
            return value
        }

        return nil
    }
}

protocol APIDataClient: APIClient {
    func sendData(_ endpoint: APIEndpoint) async throws -> APIDataResponse
}

struct EmptyRequestBody: Encodable, Sendable {}

final class DefaultAPIClient: APIDataClient, @unchecked Sendable {
    private let environment: AppEnvironment
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenStore: AuthTokenStorage
    private let organizationSelectionStore: OrganizationSelectionStoring
    private let tokenRefreshCoordinator: TokenRefreshCoordinating
    private let deviceInfoProvider: DeviceInfoProviding
    
    init(
        environment: AppEnvironment,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder.nexo,
        encoder: JSONEncoder = JSONEncoder.nexo,
        tokenStore: AuthTokenStorage,
        organizationSelectionStore: OrganizationSelectionStoring,
        tokenRefreshCoordinator: TokenRefreshCoordinating,
        deviceInfoProvider: DeviceInfoProviding = DefaultDeviceInfoProvider(
            buildInfo: .current(),
            deviceIdentityStore: UserDefaultsDeviceIdentityStore()
        )
    ) {
        self.environment = environment
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.tokenStore = tokenStore
        self.organizationSelectionStore = organizationSelectionStore
        self.tokenRefreshCoordinator = tokenRefreshCoordinator
        self.deviceInfoProvider = deviceInfoProvider
    }
    
    func send<Response: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> Response {
        try await perform(endpoint, body: Optional<EmptyRequestBody>.none, didRetryAfterRefresh: false)
    }
    
    func send<Body: Encodable & Sendable, Response: Decodable & Sendable>(_ endpoint: APIEndpoint, body: Body) async throws -> Response {
        try await perform(endpoint, body: body, didRetryAfterRefresh: false)
    }

    func sendData(_ endpoint: APIEndpoint) async throws -> APIDataResponse {
        try await performData(endpoint, didRetryAfterRefresh: false)
    }

    private func performData(
        _ endpoint: APIEndpoint,
        didRetryAfterRefresh: Bool
    ) async throws -> APIDataResponse {
        let request = try buildRequest(endpoint, body: Optional<EmptyRequestBody>.none)

        #if DEBUG
        debugPrintRequest(request, includeBody: false)
        #endif

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.transport("Respuesta HTTP inválida.")
            }

            #if DEBUG
            debugPrintResponse(data: data, httpResponse: httpResponse, urlRequest: request)
            #endif

            if httpResponse.statusCode == 401, endpoint.requiresAuth, !didRetryAfterRefresh {
                let refreshed = try await tokenRefreshCoordinator.refreshIfNeeded()
                if refreshed {
                    return try await performData(endpoint, didRetryAfterRefresh: true)
                }
            }

            try validate(httpResponse: httpResponse, data: data)

            return APIDataResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.nexoStringHeaders
            )
        } catch let appError as AppError {
            throw appError
        } catch {
            #if DEBUG
            print("❌ API TRANSPORT ERROR")
            print(error.localizedDescription)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            throw AppError.transport(error.localizedDescription)
        }
    }
    
    private func perform<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        didRetryAfterRefresh: Bool
    ) async throws -> Response {
        let request = try buildRequest(endpoint, body: body)
        
        #if DEBUG
        debugPrintRequest(request, includeBody: body != nil)
        #endif
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.transport("Respuesta HTTP inválida.")
            }
            
            #if DEBUG
            debugPrintResponse(data: data, httpResponse: httpResponse, urlRequest: request)
            #endif
            
            if httpResponse.statusCode == 401, endpoint.requiresAuth, !didRetryAfterRefresh {
                let refreshed = try await tokenRefreshCoordinator.refreshIfNeeded()
                if refreshed {
                    return try await perform(endpoint, body: body, didRetryAfterRefresh: true)
                }
            }
            
            try validate(httpResponse: httpResponse, data: data)
            
            if Response.self == EmptyResponse.self {
                return EmptyResponse() as! Response
            }
            
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                #if DEBUG
                print("❌ DECODING ERROR")
                print(error)
                print("EXPECTED RESPONSE TYPE:", Response.self)
                if let responseString = String(data: data, encoding: .utf8) {
                    print("RAW BODY:")
                    print(responseString)
                } else {
                    print("RAW BODY: <\(data.count) bytes>")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                #endif
                
                throw AppError.decoding(error.localizedDescription)
            }
        } catch let appError as AppError {
            throw appError
        } catch {
            #if DEBUG
            print("❌ API TRANSPORT ERROR")
            print(error.localizedDescription)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            
            throw AppError.transport(error.localizedDescription)
        }
    }
    
    private func buildRequest<Body: Encodable>(_ endpoint: APIEndpoint, body: Body?) throws -> URLRequest {
        guard var components = URLComponents(url: environment.baseURL.appendingNexoPath(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw AppError.invalidURL
        }
        
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        
        guard let url = components.url else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("NexoAdminIOS", forHTTPHeaderField: APIRequestHeaders.clientApp)
        request.setValue(deviceInfoProvider.deviceId, forHTTPHeaderField: APIRequestHeaders.deviceId)
        request.setValue(deviceInfoProvider.appType, forHTTPHeaderField: APIRequestHeaders.appType)
        request.setValue(deviceInfoProvider.appVersion, forHTTPHeaderField: APIRequestHeaders.appVersion)
        request.setValue(endpoint.correlationId ?? UUID().uuidString.lowercased(), forHTTPHeaderField: APIRequestHeaders.correlationId)
        
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if endpoint.requiresAuth, let accessToken = try tokenStore.readTokens()?.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if endpoint.requiresOrganization, let organizationId = organizationSelectionStore.selectedOrganizationId {
            request.setValue(organizationId, forHTTPHeaderField: APIRequestHeaders.organizationId)
        }
        
        if let branchId = endpoint.branchId?.trimmingCharacters(in: .whitespacesAndNewlines), !branchId.isEmpty {
            request.setValue(branchId, forHTTPHeaderField: APIRequestHeaders.branchId)
        }
        
        if let idempotencyKey = endpoint.idempotencyKey?.trimmingCharacters(in: .whitespacesAndNewlines), !idempotencyKey.isEmpty {
            request.setValue(idempotencyKey, forHTTPHeaderField: APIRequestHeaders.idempotencyKey)
        }
        
        if let catalogRevision = endpoint.catalogRevision?.trimmingCharacters(in: .whitespacesAndNewlines), !catalogRevision.isEmpty {
            request.setValue(catalogRevision, forHTTPHeaderField: APIRequestHeaders.catalogRevision)
        }
        
        if let body {
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
    
    private func validate(httpResponse: HTTPURLResponse, data: Data) throws {
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 400:
            throw AppError.validation(decodeAPIError(data).bestMessage)
        case 401:
            throw AppError.unauthorized
        case 403:
            throw AppError.forbidden
        case 404:
            throw AppError.notFound
        case 409, 422:
            throw AppError.validation(decodeAPIError(data).bestMessage)
        case 500..<600:
            throw AppError.server(decodeAPIError(data).bestMessage)
        default:
            throw AppError.unknown(decodeAPIError(data).bestMessage)
        }
    }
    
    private func decodeAPIError(_ data: Data) -> APIErrorResponse {
        (try? decoder.decode(APIErrorResponse.self, from: data))
        ?? APIErrorResponse(error: nil, message: String(data: data, encoding: .utf8), details: nil)
    }
    
    #if DEBUG
    private func debugPrintRequest(_ request: URLRequest, includeBody: Bool) {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("➡️ API REQUEST")
        print("METHOD:", request.httpMethod ?? "")
        print("URL:", request.url?.absoluteString ?? "")
        print("HEADERS:")
        
        request.allHTTPHeaderFields?
            .sorted { $0.key < $1.key }
            .forEach { key, value in
                print("  \(key): \(redactedHeaderValue(key: key, value: value))")
            }
        
        if includeBody, let body = request.httpBody {
            print("BODY:")
            print(debugBodyString(from: body))
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func debugPrintResponse(data: Data, httpResponse: HTTPURLResponse, urlRequest: URLRequest) {
        print("⬅️ API RESPONSE")
        print("STATUS:", httpResponse.statusCode)
        print("URL:", urlRequest.url?.absoluteString ?? "")
        
        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            print("CONTENT-TYPE:", contentType)
        }
        
        if data.isEmpty {
            print("BODY: <empty>")
        } else if let responseString = String(data: data, encoding: .utf8) {
            print("BODY:")
            print(responseString)
        } else {
            print("BYTES:", data.count)
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    private func redactedHeaderValue(key: String, value: String) -> String {
        let normalizedKey = key.lowercased()
        
        if normalizedKey == "authorization" {
            return value.lowercased().hasPrefix("bearer ")
                ? "Bearer <redacted>"
                : "<redacted>"
        }
        
        if normalizedKey == "cookie"
            || normalizedKey == "set-cookie"
            || normalizedKey.contains("api-key")
            || normalizedKey.contains("apikey") {
            return "<redacted>"
        }
        
        return value
    }
    
    private func debugBodyString(from data: Data) -> String {
        guard !data.isEmpty else {
            return "<empty>"
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
        }
        
        let redactedObject = redactSensitiveValues(in: jsonObject)
        
        if JSONSerialization.isValidJSONObject(redactedObject),
           let prettyData = try? JSONSerialization.data(
            withJSONObject: redactedObject,
            options: [.prettyPrinted, .sortedKeys]
           ),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        
        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }
    
    private func redactSensitiveValues(in object: Any) -> Any {
        switch object {
        case let dictionary as [String: Any]:
            return dictionary.reduce(into: [String: Any]()) { result, entry in
                if isSensitiveJSONKey(entry.key) {
                    result[entry.key] = "<redacted>"
                } else {
                    result[entry.key] = redactSensitiveValues(in: entry.value)
                }
            }
            
        case let array as [Any]:
            return array.map { redactSensitiveValues(in: $0) }
            
        default:
            return object
        }
    }
    
    private func isSensitiveJSONKey(_ key: String) -> Bool {
        let normalizedKey = key.lowercased()
        
        return normalizedKey == "password"
            || normalizedKey == "newpassword"
            || normalizedKey == "oldpassword"
            || normalizedKey == "currentpassword"
            || normalizedKey == "token"
            || normalizedKey == "accesstoken"
            || normalizedKey == "refreshtoken"
            || normalizedKey == "secret"
            || normalizedKey == "clientsecret"
            || normalizedKey == "apikey"
            || normalizedKey == "api_key"
            || normalizedKey == "authorization"
            || normalizedKey.contains("password")
            || normalizedKey.contains("token")
            || normalizedKey.contains("secret")
    }
    #endif
}

struct EmptyResponse: Decodable, Sendable {}

private extension HTTPURLResponse {
    var nexoStringHeaders: [String: String] {
        allHeaderFields.reduce(into: [String: String]()) { result, entry in
            guard let value = entry.value as? String else { return }
            result[String(describing: entry.key)] = value
        }
    }
}

extension URLSession: @unchecked Sendable {}

extension JSONDecoder {
    static var nexo: JSONDecoder {
        JSONDecoder()
    }
}

extension JSONEncoder {
    static var nexo: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
