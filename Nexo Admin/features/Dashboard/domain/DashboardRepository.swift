//
//  DashboardRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
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

    var emptyMessage: String {
        switch self {
        case .today: return "Todavía no hay movimiento operativo para hoy."
        case .week: return "Todavía no hay movimiento operativo para esta semana."
        case .month: return "Todavía no hay movimiento operativo para este mes."
        }
    }

    func dateRange(now: Date = Date(), calendar baseCalendar: Calendar = .autoupdatingCurrent) -> DashboardDateRange {
        var calendar = baseCalendar
        calendar.timeZone = .autoupdatingCurrent

        let interval: DateInterval
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            interval = DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: start) ?? now)
        case .week:
            interval = calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, duration: 7 * 24 * 60 * 60)
        case .month:
            interval = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 30 * 24 * 60 * 60)
        }

        return DashboardDateRange(
            businessDate: DashboardDateFormatter.dateString(from: interval.start, calendar: calendar),
            from: DashboardDateFormatter.isoString(from: interval.start),
            to: DashboardDateFormatter.isoString(from: interval.end),
            timezone: calendar.timeZone.identifier
        )
    }
}

struct DashboardDateRange: Equatable, Sendable {
    let businessDate: String
    let from: String
    let to: String
    let timezone: String
}

enum DashboardDateFormatter {
    static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    static func dateString(from date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
