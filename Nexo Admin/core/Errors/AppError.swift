//
//  AppError.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum AppError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL
    case invalidCredentials
    case unauthorized
    case forbidden
    case notFound
    case validation(String)
    case server(String)
    case decoding(String)
    case transport(String)
    case keychain(String)
    case missingSession
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "La URL configurada no es válida."
        case .invalidCredentials:
            return "Correo o contraseña incorrectos."
        case .unauthorized:
            return "Tu sesión expiró o no es válida."
        case .forbidden:
            return "No tienes permiso para realizar esta acción."
        case .notFound:
            return "El recurso solicitado no existe."
        case .validation(let message):
            return message
        case .server(let message):
            return message
        case .decoding(let message):
            return "No se pudo leer la respuesta del servidor: \(message)"
        case .transport(let message):
            return "No se pudo conectar con el servidor: \(message)"
        case .keychain(let message):
            return "Error de almacenamiento seguro: \(message)"
        case .missingSession:
            return "No hay una sesión activa."
        case .unknown(let message):
            return message
        }
    }
}

extension Error {
    var userFriendlyMessage: String {
        if let appError = self as? AppError {
            return appError.localizedDescription
        }
        return localizedDescription
    }
}
