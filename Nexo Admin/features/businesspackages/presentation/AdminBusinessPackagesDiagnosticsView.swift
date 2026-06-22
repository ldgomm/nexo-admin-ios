//
//  AdminBusinessPackagesDiagnosticsView.swift
//  Nexo Admin
//
//  Created by Nexo on 22/6/26.
//

import SwiftUI

struct AdminBusinessPackagesDiagnosticsView: View {
    @StateObject var viewModel: AdminBusinessPackagesDiagnosticsViewModel
    @State private var selectedSurface: AdminBusinessPackagesSurface = .summary
    @State private var selectedPreset: AdminVerticalPreset?
    @State private var selectedCapability: AdminCapabilityPackage?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Paquetes del negocio")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NexoAdminUXRefreshButton(isLoading: isLoading) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .sheet(item: $selectedPreset) { preset in
            NavigationStack {
                AdminVerticalPresetDetailView(preset: preset)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedCapability) { capability in
            NavigationStack {
                AdminCapabilityPackageDetailView(capability: capability)
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            NexoAdminUXLoadingState(
                title: "Cargando paquetes…",
                message: "Leyendo capabilities, verticales sugeridos, módulos activos y advertencias."
            )
            .frame(minHeight: 420)

        case .empty(let message):
            NexoAdminUXEmptyState(
                systemImage: "square.3.layers.3d.down.right",
                title: "Sin paquetes",
                message: message,
                actionTitle: "Actualizar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .failed(let message):
            NexoAdminUXEmptyState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo cargar paquetes",
                message: message,
                actionTitle: "Reintentar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .loaded(let presentation):
            AdminBusinessPackagesHero(presentation: presentation)
            AdminBusinessPackagesReadOnlyNotice()
            surfacePicker
            selectedContent(presentation)
        }
    }

    private var surfacePicker: some View {
        Picker("Vista", selection: $selectedSurface) {
            ForEach(AdminBusinessPackagesSurface.allCases) { surface in
                Text(surface.title).tag(surface)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Secciones de paquetes del negocio")
    }

    @ViewBuilder
    private func selectedContent(_ presentation: AdminBusinessPackagesDiagnosticsPresentation) -> some View {
        switch selectedSurface {
        case .summary:
            AdminBusinessPackagesSummaryCard(presentation: presentation)
            AdminBusinessPackagePresetSection(
                title: "Recomendados",
                subtitle: "Verticales sugeridos por las actividades actuales del negocio.",
                systemImage: "sparkles",
                presets: presentation.recommendedPresets,
                emptyMessage: "No hay recomendación determinística todavía.",
                onSelect: { selectedPreset = $0 }
            )
        case .presets:
            AdminBusinessPackagePresetSection(
                title: "Recomendados",
                subtitle: "Diagnóstico read-only. No activa pantallas operativas.",
                systemImage: "sparkles",
                presets: presentation.recommendedPresets,
                emptyMessage: "No hay presets recomendados.",
                onSelect: { selectedPreset = $0 }
            )
            AdminBusinessPackagePresetSection(
                title: "Disponibles ahora",
                subtitle: "Presets marcados como disponibles por backend. Activación no incluida en esta fase.",
                systemImage: "checkmark.seal",
                presets: presentation.availablePresets,
                emptyMessage: "No hay presets adicionales disponibles ahora.",
                onSelect: { selectedPreset = $0 }
            )
            AdminBusinessPackagePresetSection(
                title: "Futuros / metadata",
                subtitle: "Sirven para planificar crecimiento. No significan implementación productiva.",
                systemImage: "clock.badge.checkmark",
                presets: presentation.futurePresets,
                emptyMessage: "No hay presets futuros para mostrar.",
                onSelect: { selectedPreset = $0 }
            )
        case .capabilities:
            AdminBusinessCapabilitiesSectionsView(
                sections: presentation.capabilitySections,
                onSelect: { selectedCapability = $0 }
            )
        case .regulated:
            AdminBusinessPackageRegulatedSection(
                presets: presentation.regulatedPresets,
                onSelect: { selectedPreset = $0 }
            )
        }
    }

    private var isLoading: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return false
        }
    }
}

private enum AdminBusinessPackagesSurface: String, CaseIterable, Identifiable {
    case summary
    case presets
    case capabilities
    case regulated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: return "Resumen"
        case .presets: return "Verticales"
        case .capabilities: return "Capabilities"
        case .regulated: return "Regulados"
        }
    }
}

private struct AdminBusinessPackagesHero: View {
    let presentation: AdminBusinessPackagesDiagnosticsPresentation

    var body: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Business Package System v0",
            title: "Paquetes del negocio",
            subtitle: "Diagnóstico read-only de capabilities y verticales sugeridos. Todavía no activa funciones.",
            systemImage: "square.3.layers.3d.down.right",
            badgeTitle: "Read-only",
            badgeSystemImage: "eye"
        )
    }
}

private struct AdminBusinessPackagesReadOnlyNotice: View {
    var body: some View {
        NexoAdminUXInlineMessage(
            title: "Solo diagnóstico",
            message: "Estos paquetes ayudan a planificar el crecimiento del negocio. En esta versión no activan pantallas operativas ni cambian módulos.",
            tone: .info
        )
    }
}

private struct AdminBusinessPackagesSummaryCard: View {
    let presentation: AdminBusinessPackagesDiagnosticsPresentation

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Resumen",
                subtitle: "Actividades detectadas, módulos activos y advertencias del catálogo de paquetes.",
                systemImage: "chart.bar.doc.horizontal"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NexoAdminUXMetricTile(
                    title: "Recomendados",
                    value: "\(presentation.recommendedPresets.count)",
                    subtitle: "Presets sugeridos",
                    systemImage: "sparkles",
                    tint: .accentColor
                )
                NexoAdminUXMetricTile(
                    title: "Capabilities",
                    value: "\(presentation.totalCapabilities)",
                    subtitle: "Habilidades modeladas",
                    systemImage: "shippingbox",
                    tint: .blue
                )
                NexoAdminUXMetricTile(
                    title: "Regulados",
                    value: "\(presentation.regulatedPresets.count)",
                    subtitle: "Requieren revisión",
                    systemImage: "exclamationmark.shield",
                    tint: presentation.regulatedPresets.isEmpty ? .green : .orange
                )
                NexoAdminUXMetricTile(
                    title: "Warnings",
                    value: "\(presentation.warnings.count)",
                    subtitle: "Avisos backend",
                    systemImage: "exclamationmark.triangle",
                    tint: presentation.warnings.isEmpty ? .green : .orange
                )
            }

            AdminBusinessPackageCodeList(title: "Actividades detectadas", values: presentation.activityTypeCodes, emptyText: "Sin actividades detectadas")
            AdminBusinessPackageCodeList(title: "Módulos activos", values: presentation.activeModuleCodes, emptyText: "Sin módulos activos reportados")

            if !presentation.warnings.isEmpty {
                VStack(spacing: 8) {
                    ForEach(presentation.warnings, id: \.self) { warning in
                        NexoAdminUXInlineMessage(title: "Advertencia", message: warning, tone: .warning)
                    }
                }
            }
        }
    }
}

private struct AdminBusinessPackagePresetSection: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let presets: [AdminVerticalPreset]
    let emptyMessage: String
    let onSelect: (AdminVerticalPreset) -> Void

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(title, subtitle: subtitle, systemImage: systemImage)

            if presets.isEmpty {
                NexoAdminUXInlineMessage(title: "Sin datos", message: emptyMessage, tone: .info)
            } else {
                VStack(spacing: 12) {
                    ForEach(presets) { preset in
                        AdminVerticalPresetRow(preset: preset, onSelect: { onSelect(preset) })
                        if preset.id != presets.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

private struct AdminBusinessPackageRegulatedSection: View {
    let presets: [AdminVerticalPreset]
    let onSelect: (AdminVerticalPreset) -> Void

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Regulados",
                subtitle: "Requiere revisión normativa, privacidad y seguridad antes de implementación productiva.",
                systemImage: "exclamationmark.shield"
            )

            if presets.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin regulados",
                    message: "El backend no reportó presets regulados en este catálogo.",
                    tone: .success
                )
            } else {
                NexoAdminUXInlineMessage(
                    title: "Cuidado",
                    message: "Salud, farmacia y laboratorio no están listos para producción. No implementar datos clínicos, recetas, medicamentos controlados, dosis ni resultados clínicos sin revisión.",
                    tone: .warning
                )
                VStack(spacing: 12) {
                    ForEach(presets) { preset in
                        AdminVerticalPresetRow(preset: preset, onSelect: { onSelect(preset) })
                        if preset.id != presets.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

private struct AdminBusinessCapabilitiesSectionsView: View {
    let sections: [AdminBusinessPackageCapabilitySection]
    let onSelect: (AdminCapabilityPackage) -> Void

    var body: some View {
        if sections.isEmpty {
            NexoAdminUXEmptyState(
                systemImage: "shippingbox",
                title: "Sin capabilities",
                message: "El backend no reportó capabilities para este catálogo."
            )
        } else {
            ForEach(sections) { section in
                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        section.title,
                        subtitle: "Capabilities reutilizables agrupadas por categoría.",
                        systemImage: "shippingbox"
                    )
                    VStack(spacing: 12) {
                        ForEach(section.capabilities) { capability in
                            AdminCapabilityPackageRow(capability: capability, onSelect: { onSelect(capability) })
                            if capability.id != section.capabilities.last?.id { Divider() }
                        }
                    }
                }
            }
        }
    }
}

private struct AdminVerticalPresetRow: View {
    let preset: AdminVerticalPreset
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: preset.isRegulated ? "exclamationmark.shield.fill" : "square.3.layers.3d.down.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(statusTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(statusTint)

                VStack(alignment: .leading, spacing: 5) {
                    Text(preset.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(preset.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        AdminBusinessPackageStatusBadge(status: preset.status, regulated: preset.isRegulated)
                        if !preset.capabilityCodes.isEmpty {
                            Text("\(preset.capabilityCodes.count) capabilities")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer(minLength: 8)
                Text("Ver detalle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var statusTint: Color {
        preset.isRegulated ? .orange : preset.status.businessPackageTint
    }
}

private struct AdminCapabilityPackageRow: View {
    let capability: AdminCapabilityPackage
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.title3.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(capability.status.businessPackageTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(capability.status.businessPackageTint)

                VStack(alignment: .leading, spacing: 5) {
                    Text(capability.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(capability.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(capability.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    AdminBusinessPackageStatusBadge(status: capability.status, regulated: capability.status == .regulatedFuture)
                }
                Spacer(minLength: 8)
                Text("Ver detalle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct AdminBusinessPackageStatusBadge: View {
    let status: AdminBusinessPackageStatus
    let regulated: Bool

    var body: some View {
        NexoAdminUXStatusBadge(
            title: regulated ? "Regulado futuro" : status.title,
            systemImage: regulated ? "exclamationmark.shield" : status.businessPackageSystemImage,
            tint: regulated ? .orange : status.businessPackageTint
        )
    }
}

private struct AdminBusinessPackageCodeList: View {
    let title: String
    let values: [String]
    let emptyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if values.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.secondary.opacity(0.10), in: Capsule())
                    }
                }
            }
        }
    }
}

private struct AdminVerticalPresetDetailView: View {
    let preset: AdminVerticalPreset

    var body: some View {
        List {
            Section("Preset") {
                LabeledContent("Nombre", value: preset.displayName)
                LabeledContent("Código", value: preset.code)
                LabeledContent("Estado", value: preset.isRegulated ? "Regulado futuro" : preset.status.title)
                Text(preset.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            AdminBusinessPackageDetailListSection(title: "Tipos de negocio", values: preset.targetBusinessTypes)
            AdminBusinessPackageDetailListSection(title: "Capabilities incluidas", values: preset.capabilityCodes)
            AdminBusinessPackageDetailListSection(title: "Capabilities opcionales", values: preset.optionalCapabilityCodes)
            AdminBusinessPackageDetailListSection(title: "Módulos core relacionados", values: preset.defaultModuleCodes)
            AdminBusinessPackageDetailListSection(title: "Notas", values: preset.notes)

            if preset.isRegulated {
                Section("Advertencia regulatoria") {
                    Text("Requiere revisión normativa, privacidad y seguridad antes de implementación productiva. No tratar como listo para producción.")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AdminCapabilityPackageDetailView: View {
    let capability: AdminCapabilityPackage

    var body: some View {
        List {
            Section("Capability") {
                LabeledContent("Nombre", value: capability.displayName)
                LabeledContent("Código", value: capability.code)
                LabeledContent("Estado", value: capability.status.title)
                LabeledContent("Categoría", value: capability.categoryTitle)
                Text(capability.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            AdminBusinessPackageDetailListSection(title: "Módulos core relacionados", values: capability.coreModuleCodes)
            AdminBusinessPackageDetailListSection(title: "Permisos recomendados", values: capability.recommendedPermissionCodes)
            AdminBusinessPackageDetailListSection(title: "Depende de", values: capability.dependsOnCapabilityCodes)
            AdminBusinessPackageDetailListSection(title: "Notas", values: capability.notes)

            if !capability.readinessHints.isEmpty {
                Section("Readiness hints") {
                    ForEach(capability.readinessHints) { hint in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(hint.title)
                                    .font(.headline)
                                Spacer()
                                Text(hint.severity.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(hint.severity.businessPackageTint)
                            }
                            Text(hint.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AdminBusinessPackageDetailListSection: View {
    let title: String
    let values: [String]

    var body: some View {
        Section(title) {
            if values.isEmpty {
                Text("—")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.subheadline.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private extension AdminBusinessPackageStatus {
    var businessPackageTint: Color {
        switch self {
        case .availableNow: return .green
        case .metadataOnly: return .blue
        case .future: return .purple
        case .regulatedFuture: return .orange
        case .conceptualOnly: return .secondary
        case .unknown: return .secondary
        }
    }

    var businessPackageSystemImage: String {
        switch self {
        case .availableNow: return "checkmark.seal"
        case .metadataOnly: return "doc.text.magnifyingglass"
        case .future: return "clock"
        case .regulatedFuture: return "exclamationmark.shield"
        case .conceptualOnly: return "lightbulb"
        case .unknown: return "questionmark.circle"
        }
    }
}

private extension AdminBusinessPackageReadinessSeverity {
    var businessPackageTint: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .blocker: return .red
        case .unknown: return .secondary
        }
    }
}
