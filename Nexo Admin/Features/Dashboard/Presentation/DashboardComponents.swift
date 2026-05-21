//
//  DashboardComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct SummaryMetricsGrid: View {
    let summary: DashboardSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardMetricCard(
                title: "Ventas",
                value: summary.sales.netTotal.formatted,
                subtitle: "\(summary.sales.salesCount) ventas • ticket \(summary.sales.averageTicket.formatted)",
                systemImage: "chart.line.uptrend.xyaxis"
            )
            DashboardMetricCard(
                title: "Cobrado",
                value: summary.sales.collectedTotal.formatted,
                subtitle: "Por cobrar \(summary.sales.receivableTotal.formatted)",
                systemImage: "creditcard.fill"
            )
            DashboardMetricCard(
                title: "Caja",
                value: summary.cash.expectedCash.formatted,
                subtitle: summary.cash.isOpen ? "Caja abierta" : "Caja cerrada",
                systemImage: "banknote.fill"
            )
            DashboardMetricCard(
                title: "SRI",
                value: "\(summary.documents.authorizedCount)",
                subtitle: "\(summary.documents.pendingCount) pendientes • \(summary.documents.rejectedCount) rechazados",
                systemImage: "doc.text.fill"
            )
        }
    }
}

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

struct AlertsSection: View {
    let alerts: [DashboardAlert]

    var body: some View {
        HCard {
            HStack {
                Text("Alertas")
                    .font(.headline)
                Spacer()
                if !alerts.isEmpty {
                    Text("\(alerts.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            }

            if alerts.isEmpty {
                Text("Sin alertas críticas por ahora. Ese es el tipo de silencio que sí queremos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(alerts.prefix(6)) { alert in
                        DashboardAlertRow(alert: alert)
                    }
                }
            }
        }
    }
}

struct DashboardAlertRow: View {
    let alert: DashboardAlert

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconStyle)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.subheadline.bold())
                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let actionTitle = alert.actionTitle {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(.quaternary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var iconName: String {
        switch alert.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.seal.fill"
        }
    }

    private var iconStyle: AnyShapeStyle {
        switch alert.severity {
        case .critical: return AnyShapeStyle(.red)
        case .warning: return AnyShapeStyle(.orange)
        case .info: return AnyShapeStyle(.blue)
        case .success: return AnyShapeStyle(.green)
        }
    }
}

struct SignatureStatusCard: View {
    let signature: DashboardSignatureSummary

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                Image(systemName: signature.requiresAttention ? "signature" : "checkmark.seal.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(signature.requiresAttention ? .orange : .green)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Firma electrónica")
                        .font(.headline)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let owner = signature.ownerName {
                        Text(owner)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var statusText: String {
        if let days = signature.daysUntilExpiration {
            if days < 0 { return "Vencida hace \(abs(days)) días" }
            if days == 0 { return "Vence hoy" }
            return "Vence en \(days) días"
        }
        return "Estado: \(signature.status)"
    }
}

struct DashboardQuickActionCard: View {
    let action: DashboardQuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: action.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(action.title)
                .font(.subheadline.bold())
            Text(action.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
