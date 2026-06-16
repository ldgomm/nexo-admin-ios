import SwiftUI

struct AdminBusinessHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @StateObject private var viewModel: AdminBusinessViewModel
    @StateObject private var catalogViewModel: AdminCatalogViewModel
    let foundationRepository: any AdminFoundationRepository

    @State private var selectedFocus: AdminBusinessHomeFocus = .setup

    private let businessHomePermissions: Set<String> = [
        PermissionCatalog.organizationView
    ]

    private let catalogPermissions: Set<String> = [
        PermissionCatalog.catalogLocalView,
        PermissionCatalog.catalogLocalCopyFromMaster,
        PermissionCatalog.catalogLocalRequestNewItem
    ]

    init(
        sessionStore: AuthSessionStore,
        repository: any AdminBusinessRepository,
        catalogRepository: any AdminCatalogRepository,
        foundationRepository: any AdminFoundationRepository
    ) {
        self.sessionStore = sessionStore
        _viewModel = StateObject(wrappedValue: AdminBusinessViewModel(repository: repository))
        _catalogViewModel = StateObject(wrappedValue: AdminCatalogViewModel(repository: catalogRepository))
        self.foundationRepository = foundationRepository
    }

    var body: some View {
        NavigationStack {
            PermissionGate(
                permissions: sessionStore.effectivePermissions,
                required: businessHomePermissions
            ) {
                content
                    .navigationTitle("Negocio")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar { toolbarContent }
                    .task { await loadIfNeeded() }
                    .refreshable { await refreshAll() }
            } fallback: {
                permissionDeniedContent
                    .navigationTitle("Negocio")
            }
        }
        .safeAreaInset(edge: .top) {
            if let feedback = feedbackMessage {
                AdminBusinessFeedbackBanner(
                    kind: feedback.kind,
                    message: feedback.message,
                    dismiss: dismissMessages
                )
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackMessage?.message)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NexoAdminUXRefreshButton(isLoading: isBusy) {
                Task { await refreshAll() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.overview == nil {
            NexoAdminUXLoadingState(
                title: "Preparando el negocio…",
                message: "Estamos cargando configuración, catálogo y readiness."
            )
            .background(Color(.systemGroupedBackground))
        } else if let overview = viewModel.overview {
            loadedContent(overview)
        } else if let error = viewModel.errorMessage ?? catalogViewModel.errorMessage {
            centeredState(
                systemImage: "wifi.exclamationmark",
                title: "No se pudo cargar el negocio",
                message: error,
                actionTitle: "Reintentar",
                action: { Task { await refreshAll() } }
            )
        } else {
            centeredState(
                systemImage: "building.2.crop.circle",
                title: "Sin datos de negocio",
                message: "No encontramos la configuración de la organización activa. Revisa la sesión, la conexión o vuelve a cargar.",
                actionTitle: "Volver a cargar",
                action: { Task { await refreshAll() } }
            )
        }
    }

    private var permissionDeniedContent: some View {
        centeredState(
            systemImage: "lock.fill",
            title: "Sin permiso",
            message: "Tu usuario no tiene permisos para ver la configuración del negocio. El backend también valida cada acción.",
            actionTitle: nil,
            action: nil
        )
    }

    private func centeredState(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        VStack {
            Spacer(minLength: 24)
            NexoAdminUXEmptyState(
                systemImage: systemImage,
                title: title,
                message: message,
                actionTitle: actionTitle,
                action: action
            )
            .padding(.horizontal, 20)
            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func loadedContent(_ overview: AdminBusinessOverview) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                NexoAdminUXHeroCard(
                    eyebrow: "Panel del negocio",
                    title: overview.business.displayName,
                    subtitle: overview.business.fiscalSummary,
                    systemImage: "building.2.crop.circle",
                    badgeTitle: heroBadgeTitle(for: overview),
                    badgeSystemImage: overview.ready ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    isBusy: isBusy
                )

                AdminBusinessFocusPicker(selection: $selectedFocus, canViewCatalog: canViewCatalog)

                if selectedFocus.includes(.setup) {
                    AdminBusinessPriorityCard(
                        overview: overview,
                        primaryAction: primaryAction(from: overview.nextActions),
                        readinessDestination: {
                            AdminBusinessReadinessView(viewModel: viewModel)
                        }
                    )

                    AdminBusinessMetricStrip(counts: overview.counts)

                    operationsSection
                }

                if selectedFocus.includes(.catalog), canViewCatalog {
                    AdminBusinessCatalogPanel(
                        sessionStore: sessionStore,
                        viewModel: catalogViewModel
                    )
                }

                if selectedFocus.includes(.platform) {
                    platformSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func heroBadgeTitle(for overview: AdminBusinessOverview) -> String {
        if overview.ready {
            return "Operable · \(overview.business.status.title)"
        }

        return overview.overallStatus.title
    }

    private var operationsSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Configuración operativa",
                subtitle: "Lo necesario para que Business venda, cobre y emita sin depender de soporte.",
                systemImage: "building.2"
            )

            VStack(spacing: 10) {
                NexoAdminUXNavigationTile(
                    title: "Datos del negocio",
                    subtitle: "Razón social, nombre comercial, moneda y zona horaria.",
                    systemImage: "building.columns"
                ) {
                    AdminBusinessProfileView(
                        viewModel: viewModel,
                        permissions: sessionStore.effectivePermissions
                    )
                }

                NexoAdminUXNavigationTile(
                    title: "Actividades",
                    subtitle: "Restaurant, retail, servicios, turismo o mixto.",
                    systemImage: "square.stack.3d.up"
                ) {
                    AdminActivitiesView(
                        viewModel: viewModel,
                        permissions: sessionStore.effectivePermissions
                    )
                }

                NexoAdminUXNavigationTile(
                    title: "Sucursales y ubicación",
                    subtitle: "Dirección, privacidad, horario y puntos operativos.",
                    systemImage: "mappin.and.ellipse"
                ) {
                    AdminBranchesView(
                        viewModel: viewModel,
                        permissions: sessionStore.effectivePermissions
                    )
                }

                NexoAdminUXNavigationTile(
                    title: "Puntos de emisión",
                    subtitle: "Establecimiento, punto de emisión, secuencial y estado.",
                    systemImage: "number.square"
                ) {
                    AdminEmissionPointsView(
                        viewModel: viewModel,
                        permissions: sessionStore.effectivePermissions
                    )
                }

                NexoAdminUXNavigationTile(
                    title: "Readiness operativo",
                    subtitle: "Checklist humano antes de vender, cobrar y emitir documentos.",
                    systemImage: "checklist.checked"
                ) {
                    AdminBusinessReadinessView(viewModel: viewModel)
                }
            }
        }
    }

    private var platformSection: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Plataforma",
                subtitle: "Módulos activos, contexto operativo y readiness técnico del negocio.",
                systemImage: "puzzlepiece.extension"
            )

            NexoAdminUXNavigationTile(
                title: "Módulos y foundation",
                subtitle: "Business Context, módulos activos, catalog revision, realtime y problemas técnicos.",
                systemImage: "puzzlepiece.extension"
            ) {
                AdminFoundationHomeView(
                    viewModel: AdminFoundationViewModel(
                        repository: foundationRepository,
                        permissions: sessionStore.effectivePermissions
                    )
                )
            }
        }
    }

    private var canViewCatalog: Bool {
        PermissionSet(values: sessionStore.effectivePermissions).canAny(catalogPermissions)
    }

    private var isBusy: Bool {
        viewModel.isLoading || catalogViewModel.isLoading
    }

    private var feedbackMessage: AdminBusinessFeedback? {
        if let error = viewModel.errorMessage ?? catalogViewModel.errorMessage {
            return AdminBusinessFeedback(kind: .error, message: error)
        }
        if let success = viewModel.successMessage ?? catalogViewModel.successMessage {
            return AdminBusinessFeedback(kind: .success, message: success)
        }
        return nil
    }

    private func loadIfNeeded() async {
        if viewModel.overview == nil {
            await viewModel.load()
        }
        if canViewCatalog && catalogViewModel.localItems.isEmpty && catalogViewModel.requests.isEmpty {
            await catalogViewModel.load()
        }
    }

    private func refreshAll() async {
        await viewModel.refresh()
        if canViewCatalog {
            await catalogViewModel.refresh()
        }
    }

    private func dismissMessages() {
        viewModel.errorMessage = nil
        viewModel.successMessage = nil
        catalogViewModel.errorMessage = nil
        catalogViewModel.successMessage = nil
    }

    private func primaryAction(from actions: [AdminBusinessNextAction]) -> AdminBusinessNextAction? {
        actions.first(where: { $0.required }) ?? actions.first
    }
}

private enum AdminBusinessHomeFocus: String, CaseIterable, Identifiable {
    case setup
    case catalog
    case platform
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .setup:
            return "Base"
        case .catalog:
            return "Catálogo"
        case .platform:
            return "Plataforma"
        case .all:
            return "Todo"
        }
    }

    func includes(_ focus: AdminBusinessHomeFocus) -> Bool {
        self == .all || self == focus
    }
}

private struct AdminBusinessFeedback: Equatable {
    let kind: AdminBusinessFeedbackKind
    let message: String
}

private enum AdminBusinessFeedbackKind: Equatable {
    case success
    case error

    var tone: NexoAdminUXInlineMessage.Tone {
        switch self {
        case .success:
            return .success
        case .error:
            return .danger
        }
    }

    var title: String {
        switch self {
        case .success:
            return "Listo"
        case .error:
            return "No se pudo completar"
        }
    }
}

private struct AdminBusinessFeedbackBanner: View {
    let kind: AdminBusinessFeedbackKind
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            NexoAdminUXInlineMessage(
                title: kind.title,
                message: message,
                tone: kind.tone
            )

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.thinMaterial, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar mensaje")
        }
    }
}

private struct AdminBusinessFocusPicker: View {
    @Binding var selection: AdminBusinessHomeFocus
    let canViewCatalog: Bool

    private var visibleCases: [AdminBusinessHomeFocus] {
        AdminBusinessHomeFocus.allCases.filter { focus in
            focus != .catalog || canViewCatalog
        }
    }

    var body: some View {
        Picker("Sección", selection: $selection) {
            ForEach(visibleCases) { focus in
                Text(focus.title).tag(focus)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: canViewCatalog) { _, newValue in
            if !newValue && selection == .catalog {
                selection = .setup
            }
        }
        .accessibilityLabel("Filtrar secciones del negocio")
    }
}

private struct AdminBusinessPriorityCard<ReadinessDestination: View>: View {
    let overview: AdminBusinessOverview
    let primaryAction: AdminBusinessNextAction?
    let readinessDestination: () -> ReadinessDestination

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Prioridad ahora",
                subtitle: overview.ready ? "La base operativa está lista. Mantén el readiness revisado antes del piloto." : "Resuelve primero lo que bloquea operación, ventas o emisión documental.",
                systemImage: overview.ready ? "checkmark.seal" : "exclamationmark.triangle"
            )

            if let primaryAction {
                AdminBusinessActionSummary(action: primaryAction)
            } else {
                NexoAdminUXInlineMessage(
                    title: "Sin pendientes críticos",
                    message: "La configuración mínima está lista. El siguiente paso es validar el flujo real desde Business.",
                    tone: .success
                )
            }

            NexoAdminUXNavigationTile(
                title: "Ver readiness completo",
                subtitle: "Revisa checks, bloqueos y recomendaciones antes del piloto.",
                systemImage: "checklist.checked"
            ) {
                readinessDestination()
            }
        }
    }
}

private struct AdminBusinessActionSummary: View {
    let action: AdminBusinessNextAction

    var body: some View {
        NexoAdminUXInlineMessage(
            title: action.required ? "Bloqueante · \(action.status.title)" : "Recomendado · \(action.status.title)",
            message: "\(action.action)\n\(action.code.readableSnakeCase)",
            tone: action.required ? .danger : .warning
        )
    }
}

private struct AdminBusinessMetricStrip: View {
    let counts: AdminBusinessFoundationCounts

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            NexoAdminUXMetricTile(
                title: "Actividades",
                value: "\(counts.activeActivities)/\(counts.totalActivities)",
                subtitle: "activas configuradas",
                systemImage: "square.stack.3d.up"
            )
            NexoAdminUXMetricTile(
                title: "Sucursales",
                value: "\(counts.activeBranches)/\(counts.totalBranches)",
                subtitle: "puntos operativos",
                systemImage: "mappin.and.ellipse"
            )
            NexoAdminUXMetricTile(
                title: "Emisión",
                value: "\(counts.activeEmissionPoints)/\(counts.totalEmissionPoints)",
                subtitle: "puntos SRI",
                systemImage: "number.square"
            )
            NexoAdminUXMetricTile(
                title: "Readiness",
                value: "\(counts.readyChecks)/\(counts.readinessChecks)",
                subtitle: "checks listos",
                systemImage: "checklist.checked"
            )
        }
    }
}

private struct AdminBusinessCatalogPanel: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @ObservedObject var viewModel: AdminCatalogViewModel

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Catálogo del negocio",
                subtitle: "Lo que Business puede vender. El maestro se copia; precio e impuestos se gobiernan localmente.",
                systemImage: "square.grid.2x2"
            )

            if viewModel.isLoading && viewModel.localItems.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Cargando catálogo…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                catalogSummary
                catalogActions
                recentCatalogItems
                recentCatalogRequests
            }
        }
    }

    private var catalogSummary: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            NexoAdminUXMetricTile(
                title: "Ítems activos",
                value: "\(viewModel.activeItemsCount)",
                subtitle: "listos para vender",
                systemImage: "checkmark.seal"
            )
            NexoAdminUXMetricTile(
                title: "Solicitudes",
                value: "\(viewModel.pendingRequestsCount)",
                subtitle: "pendientes o con información requerida",
                systemImage: "tray.full"
            )
        }
    }

    private var catalogActions: some View {
        VStack(spacing: 10) {
            NexoAdminUXNavigationTile(
                title: "Catálogo local",
                subtitle: "Buscar, editar precio, tax profile, activar o desactivar.",
                systemImage: "shippingbox"
            ) {
                AdminCatalogLocalItemsView(sessionStore: sessionStore, viewModel: viewModel)
            }

            NexoAdminUXNavigationTile(
                title: "Copiar desde maestro",
                subtitle: "Traer productos gobernados sin ensuciar datos globales.",
                systemImage: "doc.on.doc"
            ) {
                AdminCatalogMasterSearchView(sessionStore: sessionStore, viewModel: viewModel)
            }

            NexoAdminUXNavigationTile(
                title: "Solicitudes de catálogo",
                subtitle: "Pedir productos o servicios que no existen en el maestro.",
                systemImage: "plus.message"
            ) {
                AdminCatalogRequestsView(sessionStore: sessionStore, viewModel: viewModel)
            }
        }
    }

    private var recentCatalogItems: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminBusinessSubsectionHeader(title: "Productos recientes", count: viewModel.localItems.count)

            if viewModel.localItems.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin catálogo local",
                    message: "Copia productos del maestro o crea una solicitud para preparar lo que Business podrá vender.",
                    tone: .info
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.localItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            AdminCatalogLocalItemDetailView(
                                sessionStore: sessionStore,
                                viewModel: viewModel,
                                item: item
                            )
                        } label: {
                            AdminCatalogItemRow(item: item)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.localItems.count, 4) - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var recentCatalogRequests: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminBusinessSubsectionHeader(title: "Solicitudes recientes", count: viewModel.requests.count)

            if viewModel.requests.isEmpty {
                NexoAdminUXInlineMessage(
                    title: "Sin solicitudes pendientes",
                    message: "Cuando falte un producto o servicio del maestro, quedará aquí para seguimiento.",
                    tone: .success
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.requests.prefix(3).enumerated()), id: \.element.id) { index, request in
                        NavigationLink {
                            AdminCatalogRequestDetailView(viewModel: viewModel, request: request)
                        } label: {
                            AdminCatalogRequestRow(request: request)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.requests.count, 3) - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

private struct AdminBusinessSubsectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.10), in: Capsule())
            Spacer(minLength: 0)
        }
    }
}
