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

struct EmptyRequestBody: Encodable, Sendable {}

final class DefaultAPIClient: APIClient, @unchecked Sendable {
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
    
    private func perform<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        body: Body?,
        didRetryAfterRefresh: Bool
    ) async throws -> Response {
        let request = try buildRequest(endpoint, body: body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.transport("Respuesta HTTP inválida.")
            }
            
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
                throw AppError.decoding(error.localizedDescription)
            }
        } catch let appError as AppError {
            throw appError
        } catch {
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
        guard let url = components.url else { throw AppError.invalidURL }
        
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
}

struct EmptyResponse: Decodable, Sendable {}

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
