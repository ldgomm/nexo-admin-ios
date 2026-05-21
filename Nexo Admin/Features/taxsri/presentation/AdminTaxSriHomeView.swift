import SwiftUI

struct AdminTaxSriHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @StateObject private var viewModel: AdminTaxSriViewModel

    init(sessionStore: AuthSessionStore, repository: any AdminTaxSriRepository) {
        self.sessionStore = sessionStore
        _viewModel = StateObject(wrappedValue: AdminTaxSriViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            PermissionGate(
                permissions: sessionStore.effectivePermissions,
                required: [PermissionCatalog.taxSettingsView, PermissionCatalog.signatureViewMetadata, PermissionCatalog.documentsElectronicInvoiceManageSettings]
            ) {
                content
                    .navigationTitle("Fiscal/SRI")
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { Task { await viewModel.refresh() } } label: { Image(systemName: "arrow.clockwise") } } }
                    .task { if viewModel.taxSettings == nil { await viewModel.load() } }
                    .refreshable { await viewModel.refresh() }
                    .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(viewModel.errorMessage ?? "") }
                    .alert("Listo", isPresented: Binding(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(viewModel.successMessage ?? "") }
            } fallback: {
                EmptyStateView(systemImage: "lock.fill", title: "Sin permiso", message: "Tu usuario no tiene permisos para configuración tributaria, firma o SRI.")
                    .navigationTitle("Fiscal/SRI")
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.taxSettings == nil {
                    ProgressView("Cargando configuración fiscal…").padding(.top, 80)
                } else {
                    AdminTaxSriOverviewView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                    AdminTaxSettingsView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                    AdminTaxProfilesView(viewModel: viewModel)
                    AdminElectronicSignaturesView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                    AdminSriSettingsView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                    AdminSriReadinessView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                    AdminSriHomologationView(viewModel: viewModel, permissions: sessionStore.effectivePermissions)
                }
            }
            .padding(16)
        }
    }
}

private struct AdminTaxSriOverviewView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>

    var body: some View {
        AdminTaxSriSectionCard(title: "Estado fiscal", subtitle: "Resumen de tributario, firma y ambiente SRI", systemImage: "checklist.checked") {
            HStack(spacing: 10) {
                metric("Readiness", viewModel.readiness?.status.capitalized ?? "—")
                metric("Firma activa", viewModel.activeSignature?.alias ?? "No")
                metric("Ambiente", viewModel.sriSettings?.environment.uppercased() ?? "—")
            }
            if viewModel.hasReadinessBlockers {
                Text("Hay bloqueos antes de emitir electrónicamente.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }
            if viewModel.hasSignatureExpiringSoon {
                Text("Una firma electrónica vence pronto. Revísala antes de producción.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.bold)).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.thinMaterial))
    }
}

private struct AdminTaxSettingsView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showEdit = false

    var body: some View {
        AdminTaxSriSectionCard(title: "Configuración tributaria", subtitle: "Régimen, contabilidad y leyendas fiscales", systemImage: "percent") {
            if let settings = viewModel.taxSettings {
                AdminTaxSriInfoRow(title: "Régimen", value: "\(settings.regimeName) (\(settings.regimeCode))", systemImage: "building.columns")
                AdminTaxSriInfoRow(title: "Obligado a contabilidad", value: settings.obligatedToKeepAccounting ? "Sí" : "No", systemImage: "book.closed")
                AdminTaxSriInfoRow(title: "Moneda", value: settings.defaultCurrency, systemImage: "dollarsign.circle")
                AdminTaxSriInfoRow(title: "Leyenda RIMPE", value: settings.rimpeLegend ?? "—", systemImage: "text.quote")
                if PermissionSet(permissions).can(PermissionCatalog.taxSettingsUpdateOrganizationRegime) {
                    Button("Editar tributario") { showEdit = true }.buttonStyle(.borderedProminent)
                }
            } else {
                Text("No hay configuración tributaria cargada.").foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showEdit) { TaxSettingsEditSheet(viewModel: viewModel) { showEdit = false } }
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
                Section("Datos") {
                    TextField("Régimen", text: $regimeCode)
                    Toggle("Obligado a llevar contabilidad", isOn: $obligated)
                    TextField("Leyenda RIMPE", text: $rimpeLegend)
                }
                Section("Motivo") { TextField("Motivo de auditoría", text: $reason, axis: .vertical).lineLimit(3, reservesSpace: true) }
            }
            .onAppear {
                regimeCode = viewModel.taxSettings?.regimeCode ?? ""
                obligated = viewModel.taxSettings?.obligatedToKeepAccounting ?? false
                rimpeLegend = viewModel.taxSettings?.rimpeLegend ?? ""
            }
            .navigationTitle("Editar tributario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            await viewModel.updateTaxSettings(UpdateAdminTaxSettingsInput(regimeCode: regimeCode, obligatedToKeepAccounting: obligated, rimpeLegend: rimpeLegend, reason: reason))
                            onClose()
                        }
                    }.disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
