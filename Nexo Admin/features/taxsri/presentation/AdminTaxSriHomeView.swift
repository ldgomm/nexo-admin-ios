//
//  AdminTaxSriHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminTaxSriHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @StateObject private var viewModel: AdminTaxSriViewModel
    @State private var selectedSurface: AdminTaxSriSurface = .summary
    private let electronicDocumentRepository: (any AdminElectronicDocumentRepository)?

    init(
        sessionStore: AuthSessionStore,
        repository: any AdminTaxSriRepository,
        electronicDocumentRepository: (any AdminElectronicDocumentRepository)? = nil
    ) {
        self.sessionStore = sessionStore
        self.electronicDocumentRepository = electronicDocumentRepository
        _viewModel = StateObject(wrappedValue: AdminTaxSriViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if canOpenFiscalSri {
                    content
                        .navigationTitle("Fiscal/SRI")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NexoAdminUXRefreshButton(isLoading: viewModel.isLoading) {
                                    Task { await viewModel.refresh() }
                                }
                            }
                        }
                        .task { if viewModel.taxSettings == nil { await viewModel.load() } }
                        .refreshable { await viewModel.refresh() }
                } else {
                    NexoAdminUXEmptyState(
                        systemImage: "lock.fill",
                        title: "Sin permiso",
                        message: "Tu usuario no tiene permisos para configuración tributaria, firma o SRI. Pide acceso a un administrador de la organización."
                    )
                    .padding(16)
                    .navigationTitle("Fiscal/SRI")
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var content: some View {
        Group {
            if viewModel.isLoading && viewModel.taxSettings == nil {
                NexoAdminUXLoadingState(
                    title: "Cargando configuración fiscal…",
                    message: "Revisando tributario, firma electrónica, ambiente SRI, readiness y homologación."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        messageBanner
                        fiscalHero
                        surfacePicker
                        selectedContent
                    }
                    .padding(16)
                }
            }
        }
    }

    @ViewBuilder
    private var messageBanner: some View {
        if let message = viewModel.errorMessage {
            NexoAdminUXInlineMessage(title: "No se pudo completar", message: message, tone: .danger)
                .onTapGesture { viewModel.errorMessage = nil }
        } else if let message = viewModel.successMessage {
            NexoAdminUXInlineMessage(title: "Listo", message: message, tone: .success)
                .onTapGesture { viewModel.successMessage = nil }
        }
    }

    private var fiscalHero: some View {
        NexoAdminUXHeroCard(
            eyebrow: "Centro fiscal",
            title: fiscalTitle,
            subtitle: fiscalSubtitle,
            systemImage: "building.columns.fill",
            badgeTitle: viewModel.readiness?.status.capitalized ?? "Sin readiness",
            badgeSystemImage: viewModel.hasReadinessBlockers ? "xmark.octagon.fill" : "checkmark.seal.fill",
            isBusy: viewModel.isLoading
        )
    }

    private var fiscalTitle: String {
        if viewModel.hasReadinessBlockers { return "Hay bloqueos antes de emitir" }
        if viewModel.hasSignatureExpiringSoon { return "Firma próxima a vencer" }
        return "Configuración fiscal controlada"
    }

    private var fiscalSubtitle: String {
        let environment = viewModel.sriSettings?.environment.uppercased() ?? "ambiente sin definir"
        let signature = viewModel.activeSignature?.alias ?? "sin firma activa"
        return "Ambiente \(environment) · Firma: \(signature) · Mantén esto simple, verificable y con auditoría."
    }

    private var surfacePicker: some View {
        Picker("Vista", selection: $selectedSurface) {
            ForEach(AdminTaxSriSurface.allCases) { surface in
                Text(surface.title).tag(surface)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Secciones fiscales")
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSurface {
        case .summary:
            summaryContent
        case .tax:
            taxContent
        case .signature:
            signatureContent
        case .sri:
            sriContent
        case .all:
            summaryContent
            taxContent
            signatureContent
            sriContent
        }
    }

    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            AdminTaxSriOverviewView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)

            if viewModel.hasReadinessBlockers {
                NexoAdminUXInlineMessage(
                    title: "Bloqueo de emisión",
                    message: "Antes de producción debes resolver los checks de readiness. La app debe decir claramente qué falta y no permitir acciones que aparenten estar listas.",
                    tone: .danger
                )
            } else if viewModel.hasSignatureExpiringSoon {
                NexoAdminUXInlineMessage(
                    title: "Revisa la firma",
                    message: "Una firma electrónica próxima a vencer puede bloquear emisión. Renueva o carga otra antes de operar en serio.",
                    tone: .warning
                )
            } else {
                NexoAdminUXInlineMessage(
                    title: "Sin bloqueos críticos visibles",
                    message: "Aun así, valida ambiente, firma y readiness antes de emitir documentos reales.",
                    tone: .success
                )
            }
        }
    }

    private var taxContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            AdminTaxSettingsView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            AdminTaxProfilesView(viewModel: viewModel)
        }
    }

    private var signatureContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Firma electrónica",
                    subtitle: "Carga, valida y deja activa solo la firma que el backend debe usar. El móvil no debe custodiar contraseñas ni firmar XML.",
                    systemImage: "signature"
                )
                AdminElectronicSignaturesView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            }
        }
    }

    private var sriContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Ambiente y conexión SRI",
                    subtitle: "Mantén pruebas y producción claramente separados. La UI no debe hacer creer que producción está lista si falta readiness.",
                    systemImage: "server.rack"
                )
                AdminSriSettingsView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            }

            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Readiness",
                    subtitle: "Checklist accionable: qué falta, qué está bien y qué debe corregirse antes de emitir.",
                    systemImage: "checklist.checked"
                )
                AdminSriReadinessView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
            }

            NexoAdminUXCard {
                NexoAdminUXSectionHeader(
                    "Homologación",
                    subtitle: "Debe ejecutarse solo si el backend y los datos están preparados. Evita botones muertos o ambiguos.",
                    systemImage: "testtube.2"
                )
                AdminSriHomologationView(
                    viewModel: viewModel,
                    permissions: sessionStore.effectivePermissions,
                    electronicDocumentRepository: electronicDocumentRepository
                )
            }
        }
    }

    private var canOpenFiscalSri: Bool {
        PermissionSet(sessionStore.effectivePermissions).canAny([
            PermissionCatalog.taxSettingsView,
            PermissionCatalog.signatureViewMetadata,
            PermissionCatalog.documentsElectronicInvoiceManageSettings
        ])
    }
}

private enum AdminTaxSriSurface: String, CaseIterable, Identifiable {
    case summary
    case tax
    case signature
    case sri
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .summary: return "Resumen"
        case .tax: return "Tributario"
        case .signature: return "Firma"
        case .sri: return "SRI"
        case .all: return "Todo"
        }
    }
}

private struct AdminTaxSriOverviewView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Estado fiscal",
                subtitle: "Resumen humano de tributario, firma y ambiente SRI.",
                systemImage: "checklist.checked"
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NexoAdminUXMetricTile(
                    title: "Readiness",
                    value: viewModel.readiness?.status.capitalized ?? "—",
                    subtitle: viewModel.hasReadinessBlockers ? "Tiene bloqueos" : "Sin bloqueo visible",
                    systemImage: viewModel.hasReadinessBlockers ? "xmark.octagon" : "checkmark.seal",
                    tint: viewModel.hasReadinessBlockers ? .red : .green
                )
                NexoAdminUXMetricTile(
                    title: "Firma activa",
                    value: viewModel.activeSignature?.alias ?? "No",
                    subtitle: viewModel.hasSignatureExpiringSoon ? "Vence pronto" : "Firma configurada",
                    systemImage: "signature",
                    tint: viewModel.hasSignatureExpiringSoon ? .orange : .accentColor
                )
                NexoAdminUXMetricTile(
                    title: "Ambiente",
                    value: viewModel.sriSettings?.environment.uppercased() ?? "—",
                    subtitle: "Pruebas/producción visibles",
                    systemImage: "server.rack",
                    tint: .blue
                )
                NexoAdminUXMetricTile(
                    title: "Permisos",
                    value: PermissionSet(permissions).can(PermissionCatalog.documentsElectronicInvoiceManageSettings) ? "Gestiona" : "Consulta",
                    subtitle: "Acciones según rol",
                    systemImage: "person.badge.key",
                    tint: .secondary
                )
            }
        }
    }
}

private struct AdminTaxSettingsView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showEdit = false

    var body: some View {
        NexoAdminUXCard {
            NexoAdminUXSectionHeader(
                "Configuración tributaria",
                subtitle: "Régimen, contabilidad, moneda y leyendas fiscales. Menos campos, más claridad.",
                systemImage: "percent"
            )

            if let settings = viewModel.taxSettings {
                VStack(spacing: 10) {
                    NexoAdminUXPlainRow(title: "Régimen", value: "\(settings.regimeName) (\(settings.regimeCode))", systemImage: "building.columns")
                    NexoAdminUXPlainRow(title: "Obligado a contabilidad", value: settings.obligatedToKeepAccounting ? "Sí" : "No", systemImage: "book.closed")
                    NexoAdminUXPlainRow(title: "Moneda", value: settings.defaultCurrency, systemImage: "dollarsign.circle")
                    NexoAdminUXPlainRow(title: "Leyenda RIMPE", value: settings.rimpeLegend ?? "—", systemImage: "text.quote")
                }

                if PermissionSet(permissions).can(PermissionCatalog.taxSettingsUpdateOrganizationRegime) {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Editar tributario", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                NexoAdminUXInlineMessage(
                    title: "Sin configuración tributaria",
                    message: "Carga estos datos antes de emitir o evaluar readiness productivo.",
                    tone: .warning
                )
            }
        }
        .sheet(isPresented: $showEdit) {
            TaxSettingsEditSheet(viewModel: viewModel) { showEdit = false }
                .presentationDetents([.medium, .large])
        }
    }
}

private struct TaxSettingsEditSheet: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let onClose: () -> Void
    @State private var regimeCode = ""
    @State private var obligated = false
    @State private var rimpeLegend = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Código de régimen", text: $regimeCode)
                        .textInputAutocapitalization(.characters)
                    Toggle("Obligado a llevar contabilidad", isOn: $obligated)
                    TextField("Leyenda RIMPE", text: $rimpeLegend)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Datos tributarios")
                } footer: {
                    Text("Cambia solo lo necesario. Este ajuste debe quedar auditado con un motivo claro.")
                }

                Section("Motivo de auditoría") {
                    TextField("Ej. actualización de régimen tributario", text: $reason, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .onAppear {
                regimeCode = viewModel.taxSettings?.regimeCode ?? ""
                obligated = viewModel.taxSettings?.obligatedToKeepAccounting ?? false
                rimpeLegend = viewModel.taxSettings?.rimpeLegend ?? ""
            }
            .navigationTitle("Editar tributario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await viewModel.updateTaxSettings(
                                UpdateAdminTaxSettingsInput(
                                    regimeCode: regimeCode,
                                    obligatedToKeepAccounting: obligated,
                                    rimpeLegend: rimpeLegend,
                                    reason: reason
                                )
                            )
                            onClose()
                        }
                    }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
