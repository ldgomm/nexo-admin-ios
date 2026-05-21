//
//  DashboardComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct DashboardHeaderCard: View {
    let userDisplayName: String
    let organizationTitle: String
    let periodSubtitle: String
    let criticalAlertCount: Int
    let isRefreshing: Bool

    var body: some View {
        HCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hola, \(userDisplayName)")
                        .font(.title2.bold())
                    Text(organizationTitle)
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                    Text(periodSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isRefreshing {
                    ProgressView()
                } else if criticalAlertCount > 0 {
                    DashboardBadge(text: "\(criticalAlertCount)", systemImage: "exclamationmark.triangle.fill", tint: .red)
                }
            }
        }
    }
}

struct DashboardPeriodPicker: View {
    @Binding var selection: DashboardPeriod

    var body: some View {
        Picker("Periodo", selection: $selection) {
            ForEach(DashboardPeriod.allCases) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct SummaryMetricsGrid: View {
    let summary: DashboardSummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardMetricCard(
                title: "Ventas",
                value: summary.sales.netTotal.formatted,
                subtitle: "\(summary.sales.salesCount) ventas • ticket \(summary.sales.averageTicket.formatted)",
                systemImage: "chart.line.uptrend.xyaxis",
                attention: false
            )
            DashboardMetricCard(
                title: "Cobrado",
                value: summary.sales.collectedTotal.formatted,
                subtitle: "Por cobrar \(summary.sales.receivableTotal.formatted)",
                systemImage: "creditcard.fill",
                attention: summary.sales.receivableTotal.amount > 0
            )
            DashboardMetricCard(
                title: "Caja",
                value: summary.cash.expectedCash.formatted,
                subtitle: summary.cash.isOpen ? "Caja abierta • \(summary.cash.movementCount) mov." : "Caja cerrada",
                systemImage: "banknote.fill",
                attention: !summary.cash.isOpen
            )
            DashboardMetricCard(
                title: "Comprobantes",
                value: "\(summary.documents.authorizedCount)/\(summary.documents.totalCount)",
                subtitle: "\(summary.documents.pendingCount) pendientes • \(summary.documents.rejectedCount) errores",
                systemImage: "doc.text.fill",
                attention: summary.documents.pendingCount > 0 || summary.documents.rejectedCount > 0
            )
        }
    }
}

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let attention: Bool

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(attention ? .orange : Color.accentColor)
                Spacer()
                if attention {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                }
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

struct DashboardOperationalStrip: View {
    let summary: DashboardSummary

    var body: some View {
        HCard {
            Text("Pulso operativo")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                DashboardMiniFact(title: "Cerradas", value: "\(summary.sales.closedCount)", systemImage: "checkmark.circle.fill")
                DashboardMiniFact(title: "Abiertas", value: "\(summary.sales.pendingCount)", systemImage: "clock.fill")
                DashboardMiniFact(title: "Canceladas", value: "\(summary.sales.canceledCount)", systemImage: "xmark.circle.fill")
                DashboardMiniFact(title: "Ítems", value: "\(summary.sales.itemCount)", systemImage: "cart.fill")
            }
        }
    }
}

struct DashboardMiniFact: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.quaternary.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct CashSummaryCard: View {
    let cash: DashboardCashSummary
    let pendingReceivables: DashboardMoney

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Caja y cobros")
                        .font(.headline)
                    Text(cash.isOpen ? "Caja abierta" : "Caja cerrada")
                        .font(.subheadline)
                        .foregroundStyle(cash.isOpen ? .green : .orange)
                }
                Spacer()
                DashboardBadge(
                    text: cash.isOpen ? "Activa" : "Atención",
                    systemImage: cash.isOpen ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    tint: cash.isOpen ? .green : .orange
                )
            }

            VStack(spacing: 8) {
                DashboardMoneyRow(title: "Efectivo esperado", value: cash.expectedCash.formatted)
                DashboardMoneyRow(title: "Entradas", value: cash.cashInflow.formatted)
                DashboardMoneyRow(title: "Salidas", value: cash.cashOutflow.formatted)
                DashboardMoneyRow(title: "Movimiento neto", value: cash.netCashMovement.formatted)
                DashboardMoneyRow(title: "Pendiente por cobrar", value: pendingReceivables.formatted)
            }
        }
    }
}

struct DocumentsSummaryCard: View {
    let documents: DashboardDocumentSummary

    var body: some View {
        HCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Comprobantes y SRI")
                        .font(.headline)
                    Text("Autorizados, pendientes y rechazados")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if documents.rejectedCount > 0 {
                    DashboardBadge(text: "Error", systemImage: "xmark.octagon.fill", tint: .red)
                } else if documents.pendingCount > 0 {
                    DashboardBadge(text: "Pendiente", systemImage: "clock.fill", tint: .orange)
                } else {
                    DashboardBadge(text: "OK", systemImage: "checkmark.seal.fill", tint: .green)
                }
            }

            VStack(spacing: 8) {
                DashboardMoneyRow(title: "Total documentado", value: documents.documentGrandTotal.formatted)
                DashboardMoneyRow(title: "IVA / impuestos", value: documents.taxTotal.formatted)
                DashboardCountRow(title: "Autorizados", value: documents.authorizedCount)
                DashboardCountRow(title: "Pendientes", value: documents.pendingCount)
                DashboardCountRow(title: "Errores", value: documents.rejectedCount)
            }
        }
    }
}

struct SignatureStatusCard: View {
    let signature: DashboardSignatureSummary
    let onAction: (() -> Void)?

    var body: some View {
        HCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(iconColor)
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
                    if let onAction {
                        Button("Revisar firma", action: onAction)
                            .font(.caption.weight(.semibold))
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Spacer()
            }
        }
    }

    private var iconName: String {
        if !signature.sourceAvailable { return "signature" }
        return signature.requiresAttention ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var iconColor: Color {
        if !signature.sourceAvailable { return .secondary }
        return signature.requiresAttention ? .orange : .green
    }

    private var statusText: String {
        guard signature.sourceAvailable else {
            return "El estado de firma se conectará con el módulo Fiscal/SRI."
        }
        if let days = signature.daysUntilExpiration {
            if days < 0 { return "Vencida hace \(abs(days)) días" }
            if days == 0 { return "Vence hoy" }
            return "Vence en \(days) días"
        }
        return "Estado: \(signature.status)"
    }
}

struct AlertsSection: View {
    let alerts: [DashboardAlert]
    let onSelect: (DashboardAlert) -> Void

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
                        DashboardAlertRow(alert: alert) {
                            onSelect(alert)
                        }
                    }
                }
            }
        }
    }
}

struct DashboardAlertRow: View {
    let alert: DashboardAlert
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(alert.title)
                            .font(.subheadline.bold())
                        Text(alert.category.title)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
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
                if alert.destination != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.quaternary.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch alert.severity {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.seal.fill"
        }
    }

    private var iconColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        case .success: return .green
        }
    }
}

struct TopItemsSection: View {
    let items: [DashboardTopItem]

    var body: some View {
        HCard {
            Text("Más vendido")
                .font(.headline)
            if items.isEmpty {
                Text("Cuando existan ventas cerradas, aquí aparecerán los productos o servicios con mayor movimiento.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 24, height: 24)
                                .background(.quaternary)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                Text("Cantidad \(item.quantityText)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.lineTotal.formatted)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                }
            }
        }
    }
}

struct QuickActionsSection: View {
    let actions: [DashboardQuickAction]
    let onSelect: (DashboardQuickAction) -> Void

    var body: some View {
        HCard {
            Text("Accesos rápidos")
                .font(.headline)
            if actions.isEmpty {
                Text("No hay accesos disponibles con tus permisos actuales.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(actions) { action in
                        DashboardQuickActionCard(action: action) {
                            onSelect(action)
                        }
                    }
                }
            }
        }
    }
}

struct DashboardQuickActionCard: View {
    let action: DashboardQuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: action.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
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
        .buttonStyle(.plain)
    }
}

struct DashboardMoneyRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct DashboardCountRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value)")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

struct DashboardBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }
}
