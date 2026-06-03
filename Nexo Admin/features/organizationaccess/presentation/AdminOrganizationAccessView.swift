import SwiftUI

struct AdminOrganizationAccessView: View {
    @State var viewModel: AdminOrganizationAccessViewModel

    var body: some View {
        Form {
            Section("Módulos") {
                TextField("Tipo de negocio", text: $viewModel.businessType)
                TextField("Motivo", text: $viewModel.reason, axis: .vertical)
                    .lineLimit(2...4)
                Button("Guardar módulos") {
                    Task { await viewModel.saveModules() }
                }
            }

            Section("Super Empresa") {
                TextField("Correo", text: $viewModel.superAdminEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Nombre", text: $viewModel.superAdminName)
                TextField("Teléfono", text: $viewModel.superAdminPhone)
                    .keyboardType(.phonePad)
                Button("Crear Super Empresa") {
                    Task { await viewModel.createSuperAdmin() }
                }
                if let temporaryPassword = viewModel.temporaryPassword {
                    Text(temporaryPassword)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled)
                }
            }

            Section("Estado") {
                switch viewModel.state {
                case .idle:
                    Text("Sin cargar")
                case .loading:
                    ProgressView()
                case .loaded(let settings):
                    LabeledContent("Tipo", value: settings.businessType)
                    LabeledContent("Activos", value: settings.enabledModules.sorted().joined(separator: ", "))
                    LabeledContent("Desactivados", value: settings.disabledModules.sorted().joined(separator: ", "))
                case .failed(let message):
                    Text(message).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Acceso organización")
        .task { await viewModel.load() }
    }
}
