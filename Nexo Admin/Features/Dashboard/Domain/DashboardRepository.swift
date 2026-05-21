//
//  DashboardRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

protocol DashboardRepository: Sendable {
    func summary(period: DashboardPeriod) async throws -> DashboardSummary
}

enum DashboardPeriod: String, CaseIterable, Identifiable, Sendable {
    case today
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Hoy"
        case .week: return "Semana"
        case .month: return "Mes"
        }
    }
}
