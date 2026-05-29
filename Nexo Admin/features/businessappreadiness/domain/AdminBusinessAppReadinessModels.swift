//
//  AdminBusinessAppReadinessModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum AdminBusinessAppReadinessStatus: String, Equatable, Sendable {
    case ready
    case warning
    case blocked
    case notApplicable
    case unknown

    var title: String {
        switch self {
        case .ready: return "Listo"
        case .warning: return "Revisar"
        case .blocked: return "Bloqueado"
        case .notApplicable: return "No aplica"
        case .unknown: return "Desconocido"
        }
    }

    var systemImage: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.octagon.fill"
        case .notApplicable: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

struct AdminBusinessAppReadinessCheck: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let status: AdminBusinessAppReadinessStatus
    let required: Bool
    let actionTitle: String?
    let destinationKey: String?
}

struct AdminBusinessAppReadinessSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let checks: [AdminBusinessAppReadinessCheck]

    var blockedRequiredCount: Int {
        checks.filter { $0.required && $0.status == .blocked }.count
    }

    var warningCount: Int {
        checks.filter { $0.status == .warning }.count
    }

    var readyCount: Int {
        checks.filter { $0.status == .ready }.count
    }
}

struct AdminBusinessAppReadinessReport: Equatable, Sendable {
    let organizationName: String
    let generatedAt: Date
    let sections: [AdminBusinessAppReadinessSection]

    var totalChecks: Int { sections.flatMap(\.checks).count }
    var readyCount: Int { sections.reduce(0) { $0 + $1.readyCount } }
    var warningCount: Int { sections.reduce(0) { $0 + $1.warningCount } }
    var blockedRequiredCount: Int { sections.reduce(0) { $0 + $1.blockedRequiredCount } }
    var readyForBusinessApp: Bool { blockedRequiredCount == 0 }

    var summaryTitle: String {
        readyForBusinessApp ? "Listo para construir Business App" : "Faltan foundations críticas"
    }

    var summaryMessage: String {
        if readyForBusinessApp {
            return warningCount == 0
                ? "La organización tiene las bases mínimas para operar desde Business App."
                : "No hay bloqueantes críticos, pero quedan \(warningCount) advertencias por revisar."
        }
        return "Hay \(blockedRequiredCount) bloqueantes obligatorios antes de avanzar con Business App financiera."
    }
}
