import SwiftUI

struct AdminFoundationHomeView: View {
    @StateObject var viewModel: AdminFoundationViewModel
    @State private var moduleForAction: AdminResolvedModule?
    @State private var selectedSurface: AdminFoundationSurface = .overview

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Foundation")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NexoAdminUXRefreshButton(isLoading: isLoading) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .safeAreaInset(edge: .top) {
            messageBanner
        }
        .sheet(item: $moduleForAction) { module in
            NavigationStack {
                AdminModuleToggleView(
                    module: module,
                    reason: $viewModel.actionDraft.reason,
                    enable: viewModel.actionDraft.enable,
                    isMutating: viewModel.isMutating,
                    onCancel: { moduleForAction = nil },
                    onConfirm: {
                        await viewModel.runToggle()
                        if viewModel.errorMessage == nil {
                            moduleForAction = nil
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var messageBanner: some View {
        if let message = viewModel.errorMessage {
            NexoAdminUXInlineMessage(title: "Error", message: message, tone: .danger)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .onTapGesture { viewModel.errorMessage = nil }
        } else if let message = viewModel.successMessage {
            NexoAdminUXInlineMessage(title: "Listo", message: message, tone: .success)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .onTapGesture { viewModel.successMessage = nil }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            NexoAdminUXLoadingState(
                title: "Cargando foundation…",
                message: "Leyendo contexto operativo, módulos, dependencias, readiness y realtime."
            )
            .frame(minHeight: 420)

        case .empty(let message):
            NexoAdminUXEmptyState(
                systemImage: "puzzlepiece.extension",
                title: "Sin datos",
                message: message,
                actionTitle: "Actualizar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .failed(let message):
            NexoAdminUXEmptyState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo cargar foundation",
                message: message,
                actionTitle: "Reintentar"
            ) {
                Task { await viewModel.refresh() }
            }

        case .loaded(let snapshot):
            FoundationHero(snapshot: snapshot)
            surfacePicker(snapshot: snapshot)
            selectedContent(snapshot)
        }
    }

    private func surfacePicker(snapshot: AdminFoundationSnapshot) -> some View {
        Picker("Vista", selection: $selectedSurface) {
            ForEach(AdminFoundationSurface.allCases) { surface in
                Text(surface.title).tag(surface)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Secciones foundation")
    }

    @ViewBuilder
    private func selectedContent(_ snapshot: AdminFoundationSnapshot) -> some View {
        switch selectedSurface {
        case .overview:
            BusinessContextSummaryCard(snapshot: snapshot)
            FoundationModulesMetrics(snapshot: snapshot)
        case .active:
            moduleListCard(title: "Módulos activos", subtitle: "Lo que el negocio tiene encendido hoy.", modules: snapshot.activeModules, snapshot: snapshot)
        case .available:
            moduleListCard(title: "Módulos disponibles", subtitle: "Pueden activarse si cumplen dependencias y permisos.", modules: snapshot.inactiveModules, snapshot: snapshot)
        case .blocked:
            blockedModulesCard(snapshot: snapshot)
        case .all:
            BusinessContextSummaryCard(snapshot: snapshot)
            FoundationModulesMetrics(snapshot: snapshot)
            blockedModulesCard(snapshot: snapshot)
            moduleListCard(title: "Módulos activos", subtitle: "Lo que el negocio tiene encendido hoy.", modules: snapshot.activeModules, snapshot: snapshot)
            moduleListCard(title: "Módulos disponibles", subtitle: "Pueden activarse si cumplen dependencias y permisos.", modules: snapshot.inactiveModules, snapshot: snapshot)
        }
    }

    private func moduleListCard(
        title: String,
        subtitle: String,
        modules: [AdminResolvedModule],
        snapshot: AdminFoundationSnapshot
    ) -> some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(title, subtitle: subtitle, systemImage: "puzzlepiece.extension")
            if modules.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Nada por aquí",
                    message: title.contains("activos") ? "No hay módulos activos adicionales." : "No hay módulos inactivos para mostrar.",
                    tone: .info
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(modules) { module in
                        ModuleRow(
                            module: module,
                            readiness: snapshot.readinessByCode[module.code],
                            canManage: viewModel.canManageModules,
                            action: { presentToggle(module) }
                        )
                        if module.id != modules.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func blockedModulesCard(snapshot: AdminFoundationSnapshot) -> some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Bloqueos",
                subtitle: "Dependencias o readiness que impiden activar módulos con seguridad.",
                systemImage: "xmark.octagon"
            )
            if snapshot.blockedModules.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin bloqueos visibles",
                    message: "No hay módulos bloqueados según el snapshot actual.",
                    tone: .success
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(snapshot.blockedModules) { module in
                        ModuleProblemRow(module: module, readiness: snapshot.readinessByCode[module.code])
                        if module.id != snapshot.blockedModules.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func presentToggle(_ module: AdminResolvedModule) {
        viewModel.prepareToggle(module: module)
        moduleForAction = module
    }

    private var isLoading: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return viewModel.isMutating
        }
    }
}

private enum AdminFoundationSurface: String, CaseIterable, Identifiable {
    case overview
    case active
    case available
    case blocked
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Estado"
        case .active: return "Activos"
        case .available: return "Disponibles"
        case .blocked: return "Bloqueos"
        case .all: return "Todo"
        }
    }
}

private struct FoundationHero: View {
    let snapshot: AdminFoundationSnapshot

    var body: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Foundation v2.4",
            title: snapshot.context.displayName,
            subtitle: snapshot.operationalSummary,
            systemImage: "puzzlepiece.extension.fill",
            badgeTitle: snapshot.context.realtime.enabled ? "Realtime ON" : "Realtime listo",
            badgeSystemImage: snapshot.context.realtime.enabled ? "bolt.fill" : "bolt.slash"
        )
    }
}

private struct FoundationModulesMetrics: View {
    let snapshot: AdminFoundationSnapshot

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Módulos",
                subtitle: "Resumen rápido de activación, disponibilidad y bloqueos.",
                systemImage: "square.grid.2x2"
            )
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NexoAdminUXMetricTile(
                    title: "Activos",
                    value: "\(snapshot.activeModules.count)",
                    subtitle: "Encendidos ahora",
                    systemImage: "checkmark.circle",
                    tint: .green
                )
                NexoAdminUXMetricTile(
                    title: "Disponibles",
                    value: "\(snapshot.inactiveModules.count)",
                    subtitle: "Listos o pendientes",
                    systemImage: "circle.grid.2x2",
                    tint: .blue
                )
                NexoAdminUXMetricTile(
                    title: "Bloqueados",
                    value: "\(snapshot.blockedModules.count)",
                    subtitle: "Requieren acción",
                    systemImage: "xmark.octagon",
                    tint: snapshot.blockedModules.isEmpty ? .green : .orange
                )
                NexoAdminUXMetricTile(
                    title: "Realtime",
                    value: snapshot.context.realtime.enabled ? "ON" : "Preparado",
                    subtitle: "SSE/contexto",
                    systemImage: "antenna.radiowaves.left.and.right",
                    tint: .accentColor
                )
            }
        }
    }
}

private struct BusinessContextSummaryCard: View {
    let snapshot: AdminFoundationSnapshot

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Contexto Business",
                subtitle: "Lo que Business recibe para operar: sucursal, revisiones, realtime y módulos.",
                systemImage: "iphone.gen2"
            )

            VStack(spacing: 10) {
                NexoAdminUXPlainRow(title: "Sucursal activa", value: snapshot.context.activeBranch?.name ?? "No definida", systemImage: "mappin.and.ellipse")
                NexoAdminUXPlainRow(title: "Catalog revision", value: "\(snapshot.context.catalogRevision)", systemImage: "tag")
                NexoAdminUXPlainRow(title: "Tax revision", value: "\(snapshot.context.taxConfigurationRevision)", systemImage: "percent")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("SSE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(snapshot.context.realtime.sseUrl)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ModuleRow: View {
    let module: AdminResolvedModule
    let readiness: AdminModuleReadinessItem?
    let canManage: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: module.active ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(module.active ? .green : .secondary)
                    .frame(width: 34, height: 34)
                    .background((module.active ? Color.green : Color.secondary).opacity(0.10), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.name)
                        .font(.headline)
                    Text(module.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text("\(module.categoryTitle) · \(module.source.nexoReadableKey) · \(module.statusTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                NexoAdminUXStatusBadge(
                    title: module.activeTitle,
                    systemImage: module.active ? "checkmark.circle.fill" : "circle",
                    tint: module.active ? .green : .secondary
                )
            }

            if let readiness, readiness.hasProblems {
                ModuleReadinessProblemsView(readiness: readiness)
            }

            if !module.dependencies.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Dependencias",
                    message: module.dependencies.joined(separator: ", "),
                    tone: .info
                )
            }

            if canManage {
                Button {
                    action()
                } label: {
                    Label(module.active ? "Desactivar módulo" : "Activar módulo", systemImage: module.active ? "pause.circle" : "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!module.active && !module.canBeEnabled)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ModuleProblemRow: View {
    let module: AdminResolvedModule
    let readiness: AdminModuleReadinessItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "xmark.octagon.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 34, height: 34)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(module.name)
                        .font(.headline)
                    Text(module.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(module.blockedReasons, id: \.self) { reason in
                Label(reason, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let readiness {
                ModuleReadinessProblemsView(readiness: readiness)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ModuleReadinessProblemsView: View {
    let readiness: AdminModuleReadinessItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(readiness.missingDependencies, id: \.self) { value in
                Label("Falta dependencia: \(value)", systemImage: "link.badge.plus")
            }
            ForEach(readiness.blockers, id: \.self) { value in
                Label(value, systemImage: "xmark.octagon")
            }
            ForEach(readiness.warnings, id: \.self) { value in
                Label(value, systemImage: "exclamationmark.triangle")
            }
        }
        .font(.caption)
        .foregroundStyle(.orange)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AdminModuleToggleView: View {
    let module: AdminResolvedModule
    @Binding var reason: String
    let enable: Bool
    let isMutating: Bool
    let onCancel: () -> Void
    let onConfirm: () async -> Void

    var body: some View {
        Form {
            Section("Módulo") {
                LabeledContent("Nombre", value: module.name)
                LabeledContent("Código", value: module.code)
                LabeledContent("Acción", value: enable ? "Activar" : "Desactivar")
            }

            if !module.blockedReasons.isEmpty && enable {
                Section("Bloqueos") {
                    ForEach(module.blockedReasons, id: \.self) { reason in
                        Label(reason, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Auditoría") {
                TextField("Motivo obligatorio", text: $reason, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
        .navigationTitle(enable ? "Activar módulo" : "Desactivar módulo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(enable ? "Activar" : "Desactivar", role: enable ? nil : .destructive) {
                    Task { await onConfirm() }
                }
                .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isMutating || (enable && !module.canBeEnabled))
            }
        }
    }
}
