//
//  ReleaseReadinessModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum ReleaseReadinessStatus: String, Equatable, Sendable {
    case passed
    case warning
    case failed
    case manual

    var title: String {
        switch self {
        case .passed: return "Listo"
        case .warning: return "Revisar"
        case .failed: return "Bloqueado"
        case .manual: return "Manual"
        }
    }

    var systemImage: String {
        switch self {
        case .passed: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.octagon.fill"
        case .manual: return "hand.tap.fill"
        }
    }
}

struct ReleaseReadinessCheck: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let status: ReleaseReadinessStatus
    let required: Bool
}

struct ReleaseReadinessSection: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let checks: [ReleaseReadinessCheck]

    var failedRequiredCount: Int {
        checks.filter { $0.required && $0.status == .failed }.count
    }

    var warningCount: Int {
        checks.filter { $0.status == .warning }.count
    }
}

struct ReleaseReadinessReport: Equatable, Sendable {
    let generatedAt: Date
    let buildInfo: BuildInfo
    let sections: [ReleaseReadinessSection]

    var totalChecks: Int {
        sections.flatMap(\.checks).count
    }

    var failedRequiredCount: Int {
        sections.reduce(0) { $0 + $1.failedRequiredCount }
    }

    var warningCount: Int {
        sections.reduce(0) { $0 + $1.warningCount }
    }

    var isReadyForInternalTestFlight: Bool {
        failedRequiredCount == 0
    }

    var summaryTitle: String {
        isReadyForInternalTestFlight ? "Listo para TestFlight interno" : "Faltan bloqueantes"
    }

    var summaryMessage: String {
        if isReadyForInternalTestFlight {
            if warningCount == 0 {
                return "El corte no tiene bloqueantes ni advertencias automáticas."
            }
            return "El corte no tiene bloqueantes. Revisa \(warningCount) advertencias antes de subir."
        }

        return "Hay \(failedRequiredCount) chequeos obligatorios bloqueados."
    }
}
