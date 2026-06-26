//
//  AdminVerticalActivationView.swift
//  Nexo Admin
//
//  Created by Nexo on 26/6/26.
//

import SwiftUI

struct AdminVerticalActivationView: View {
    @StateObject var viewModel: AdminVerticalActivationViewModel
    @State private var showActivateConfirmation = false
    @State private var showDeactivateConfirmation = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Verticales")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NexoAdminUXRefreshButton(isLoading: isLoading) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .alert("Acción completada", isPresented: successBinding) {
            Button("OK", role: .cancel) { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .alert("No se pudo completar", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .confirmationDialog(
            "Activar Restaurante v1",
            isPresented: $showActivateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Activar restaurante") {
                Task { await viewModel.activateRestaurant() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esto activa el vertical restaurante para la organización. No crea ventas paralelas, no crea menú paralelo y no toca caja/documentos/reportes.")
        }
        .confirmationDialog(
            "Desactivar Restaurante v1",
            isPresented: $showDeactivateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Desactivar restaurante", role: .destructive) {
                Task { await viewModel.deactivateRestaurant() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esto desactiva el vertical. El historial y datos core no se borran.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            NexoAdminUXLoadingState(
                title: "Cargando verticales…",
                message: "Leyendo paquetes, activaciones y readiness del vertical Restaurante v1."
            )
            .frame(minHeight: 420)

        case .empty(let message):
            NexoAdminUXEmptyState(
                systemImage: "square.3.layers.3d.down.right",
                title: "Sin verticales",
                message: message,
                actionTitle: "Actualizar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .failed(let message):
            NexoAdminUXEmptyState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo cargar verticales",
                message: message,
                actionTitle: "Reintentar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .loaded(let presentation):
            AdminVerticalHero(presentation: presentation, isBusy: viewModel.isMutating)
            AdminVerticalScopeNotice()
            AdminRestaurantActivationCard(
                presentation: presentation,
                canManage: viewModel.canManageVerticals,
                isMutating: viewModel.isMutating,
                activationReason: $viewModel.activationReason,
                deactivationReason: $viewModel.deactivationReason,
                onActivate: { showActivateConfirmation = true },
                onDeactivate: { showDeactivateConfirmation = true }
            )
            AdminVerticalReadinessCard(readiness: presentation.readiness)
            AdminVerticalCapabilitiesCard(package: presentation.package, activeCapabilities: presentation.defaultEnabledCapabilities)
            AdminVerticalSurfacesCard(package: presentation.package)
            AdminVerticalSeedsCard(package: presentation.package)
            AdminVerticalOtherPackagesCard(packages: presentation.allPackages.filter { $0.code != AdminVerticalCode.restaurant })
        }
    }

    private var isLoading: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return viewModel.isMutating
        }
    }

    private var successBinding: Binding<Bool> {
        Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct AdminVerticalHero: View {
    let presentation: AdminVerticalActivationPresentation
    let isBusy: Bool

    var body: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Fase 22B",
            title: "Vertical Foundation",
            subtitle: "Activa Restaurante v1 para esta organización sin duplicar ventas, caja, documentos, reportes ni catálogo.",
            systemImage: "square.3.layers.3d.down.right",
            badgeTitle: presentation.isRestaurantActive ? "Restaurante activo" : "Pendiente",
            badgeSystemImage: presentation.isRestaurantActive ? "checkmark.seal" : "pause.circle",
            isBusy: isBusy
        )
    }
}

private struct AdminVerticalScopeNotice: View {
    var body: some View {
        NexoAdminUXInlineMessage(
            title: "22B es activación, no operación restaurante",
            message: "Esta pantalla gobierna el vertical. Menú editable, tipos de servicio en venta, mesas y cocina quedan para 22D–22G.",
            tone: .info
        )
    }
}

private struct AdminRestaurantActivationCard: View {
    let presentation: AdminVerticalActivationPresentation
    let canManage: Bool
    let isMutating: Bool
    @Binding var activationReason: String
    @Binding var deactivationReason: String
    let onActivate: () -> Void
    let onDeactivate: () -> Void

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Restaurante v1",
                subtitle: "Paquete activable para Altos del Murco y futuros restaurantes pequeños.",
                systemImage: "fork.knife.circle"
            )

            HStack(spacing: 10) {
                NexoAdminUXStatusBadge(
                    title: presentation.package?.status.title ?? "No disponible",
                    systemImage: presentation.package == nil ? "xmark.octagon" : "shippingbox.fill",
                    tint: presentation.package == nil ? .red : .accentColor
                )
                NexoAdminUXStatusBadge(
                    title: presentation.activation?.status.title ?? "No activado",
                    systemImage: presentation.isRestaurantActive ? "checkmark.seal.fill" : "pause.circle",
                    tint: presentation.isRestaurantActive ? .green : .orange
                )
                if let version = presentation.package?.version {
                    NexoAdminUXStatusBadge(title: "v\(version)", systemImage: "number", tint: .secondary)
                }
            }

            if let package = presentation.package {
                Text(package.displayName)
                    .font(.headline)
                Text("Work mode por defecto: \(presentation.defaultWorkMode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                NexoAdminUXInlineMessage(
                    title: "Package no encontrado",
                    message: "El backend no reportó restaurant v1. Cierra 22A antes de continuar 22B.",
                    tone: .danger
                )
            }

            Divider()

            if presentation.isRestaurantActive {
                TextField("Motivo de desactivación", text: $deactivationReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                Button(role: .destructive, action: onDeactivate) {
                    if isMutating { ProgressView() } else { Label("Desactivar restaurante", systemImage: "pause.circle") }
                }
                .buttonStyle(.bordered)
                .disabled(!canManage || isMutating || deactivationReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                TextField("Motivo de activación", text: $activationReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                Button(action: onActivate) {
                    if isMutating { ProgressView() } else { Label("Activar restaurante", systemImage: "checkmark.seal") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canManage || isMutating || presentation.package == nil || activationReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !canManage {
                NexoAdminUXInlineMessage(
                    title: "Solo lectura",
                    message: "Tu usuario puede ver verticales, pero no activarlos/desactivarlos.",
                    tone: .warning
                )
            }
        }
    }
}

private struct AdminVerticalReadinessCard: View {
    let readiness: AdminVerticalReadinessResult?

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Readiness",
                subtitle: "Checks no destructivos antes de usar Restaurante v1 en operación.",
                systemImage: "checklist.checked"
            )

            if let readiness {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    NexoAdminUXMetricTile(title: "PASS", value: "\(readiness.passCount)", subtitle: "Listos", systemImage: "checkmark.seal", tint: .green)
                    NexoAdminUXMetricTile(title: "WARN", value: "\(readiness.warnCount)", subtitle: "No bloqueantes", systemImage: "exclamationmark.triangle", tint: .orange)
                    NexoAdminUXMetricTile(title: "FAIL", value: "\(readiness.failCount)", subtitle: "Bloqueos", systemImage: "xmark.octagon", tint: readiness.failCount > 0 ? .red : .green)
                }

                VStack(spacing: 10) {
                    ForEach(readiness.checks) { check in
                        AdminVerticalReadinessRow(check: check)
                        if check.id != readiness.checks.last?.id { Divider() }
                    }
                }
            } else {
                NexoAdminUXInlineMessage(
                    title: "Sin readiness",
                    message: "No se recibió respuesta de readiness para restaurant.",
                    tone: .warning
                )
            }
        }
    }
}

private struct AdminVerticalReadinessRow: View {
    let check: AdminVerticalReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: check.status.verticalSystemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(check.status.verticalTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .foregroundStyle(check.status.verticalTint)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(check.code)
                        .font(.caption.monospaced().weight(.semibold))
                    NexoAdminUXStatusBadge(title: check.status.title, systemImage: check.status.verticalSystemImage, tint: check.status.verticalTint)
                }
                Text(check.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !check.details.isEmpty {
                    Text(check.details.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " · "))
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

private struct AdminVerticalCapabilitiesCard: View {
    let package: AdminVerticalPackage?
    let activeCapabilities: [String]

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Capabilities",
                subtitle: "Se activan conservadoramente; mesas/cocina quedan apagadas hasta 22F/22G.",
                systemImage: "shippingbox"
            )

            if let package, !package.capabilities.isEmpty {
                VStack(spacing: 10) {
                    ForEach(package.capabilities) { capability in
                        AdminVerticalCapabilityRow(capability: capability, active: activeCapabilities.contains(capability.code))
                        if capability.id != package.capabilities.last?.id { Divider() }
                    }
                }
            } else {
                NexoAdminUXInlineMessage(title: "Sin capabilities", message: "El package no reportó capabilities.", tone: .warning)
            }
        }
    }
}

private struct AdminVerticalCapabilityRow: View {
    let capability: AdminVerticalCapability
    let active: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .font(.title3.weight(.semibold))
                .frame(width: 32)
                .foregroundStyle(active ? .green : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(capability.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(capability.code)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(capability.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if capability.defaultEnabled {
                NexoAdminUXStatusBadge(title: "Default", systemImage: "star", tint: .accentColor)
            }
        }
    }
}

private struct AdminVerticalSurfacesCard: View {
    let package: AdminVerticalPackage?

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Surfaces",
                subtitle: "Sugerencias de navegación/UX. No son permisos duros.",
                systemImage: "rectangle.3.group"
            )

            if let package, !package.surfaces.isEmpty {
                AdminVerticalCodeList(values: package.surfaces.map { "\($0.code) — \($0.description)" })
            } else {
                NexoAdminUXInlineMessage(title: "Sin surfaces", message: "El package no reportó surfaces.", tone: .info)
            }
        }
    }
}

private struct AdminVerticalSeedsCard: View {
    let package: AdminVerticalPackage?

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Seeds",
                subtitle: "22B solo los muestra. Aplicación real de menú Altos queda para 22H.",
                systemImage: "leaf"
            )

            if let package, !package.seedRefs.isEmpty {
                VStack(spacing: 10) {
                    ForEach(package.seedRefs) { seed in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.green)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(seed.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text(seed.code)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text("Fase: \(seed.phase)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            } else {
                NexoAdminUXInlineMessage(title: "Sin seeds", message: "No hay seeds registrados para este vertical.", tone: .info)
            }
        }
    }
}

private struct AdminVerticalOtherPackagesCard: View {
    let packages: [AdminVerticalPackage]

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Otros verticales",
                subtitle: "Deben permanecer fuera de Altos durante 22B si no están activados.",
                systemImage: "square.grid.2x2"
            )

            if packages.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin otros verticales",
                    message: "Correcto para 22B: restaurant es el único package disponible en foundation.",
                    tone: .success
                )
            } else {
                AdminVerticalCodeList(values: packages.map { "\($0.code) — \($0.displayName)" })
            }
        }
    }
}

private struct AdminVerticalCodeList: View {
    let values: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.caption)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

private extension AdminVerticalReadinessStatus {
    var verticalTint: Color {
        switch self {
        case .pass: return .green
        case .warn: return .orange
        case .fail: return .red
        case .unknown: return .secondary
        }
    }

    var verticalSystemImage: String {
        switch self {
        case .pass: return "checkmark.seal.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.octagon.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}
