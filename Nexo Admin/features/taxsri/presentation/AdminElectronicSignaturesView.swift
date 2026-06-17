//
//  AdminElectronicSignaturesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AdminElectronicSignaturesView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showUpload = false
    @State private var actionSignature: AdminElectronicSignature?
    @State private var actionKind: ActionKind?

    enum ActionKind { case validate, activate, revoke }

    var body: some View {
        AdminTaxSriSectionCard(
            title: "Firma electrónica",
            subtitle: "Sube la firma al backend. Admin no firma XML, no guarda la contraseña y no envía directo al SRI.",
            systemImage: "signature"
        ) {
            if viewModel.signatures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aún no hay firmas electrónicas registradas.")
                        .font(.subheadline.weight(.semibold))
                    Text("Carga un archivo .p12 o .pfx para que el backend pueda validarlo y custodiarlo de forma segura.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.signatures) { signature in
                    AdminElectronicSignatureRow(
                        signature: signature,
                        permissions: permissions,
                        onValidate: { actionSignature = signature; actionKind = .validate },
                        onActivate: { actionSignature = signature; actionKind = .activate },
                        onRevoke: { actionSignature = signature; actionKind = .revoke }
                    )
                    Divider()
                }
            }

            if PermissionSet(permissions).can(PermissionCatalog.signatureUpload) {
                Button {
                    showUpload = true
                } label: {
                    Label("Cargar nueva firma", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isMutating)
            }
        }
        .sheet(isPresented: $showUpload) {
            UploadSignatureSheet(viewModel: viewModel) { showUpload = false }
        }
        .sheet(
            item: Binding(
                get: { actionSignature.map { SignatureActionSheetState(signature: $0, kind: actionKind ?? .validate) } },
                set: { _ in actionSignature = nil; actionKind = nil }
            )
        ) { state in
            AdminTaxSriReasonSheet(
                title: state.title,
                actionTitle: state.actionTitle,
                onCancel: { actionSignature = nil; actionKind = nil }
            ) { reason in
                Task {
                    guard state.isAllowed else {
                        viewModel.errorMessage = state.blockedMessage
                        actionSignature = nil
                        actionKind = nil
                        return
                    }

                    switch state.kind {
                    case .validate:
                        await viewModel.validateSignature(id: state.signature.id, reason: reason)
                    case .activate:
                        await viewModel.activateSignature(id: state.signature.id, reason: reason)
                    case .revoke:
                        await viewModel.revokeSignature(id: state.signature.id, reason: reason)
                    }

                    actionSignature = nil
                    actionKind = nil
                }
            }
        }
    }
}

private struct AdminElectronicSignatureRow: View {
    let signature: AdminElectronicSignature
    let permissions: Set<String>
    let onValidate: () -> Void
    let onActivate: () -> Void
    let onRevoke: () -> Void

    private var permissionSet: PermissionSet { PermissionSet(permissions) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(signature.alias)
                        .font(.subheadline.weight(.bold))
                    Text(signature.displaySubject)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                AdminTaxSriStatusBadge(text: signature.displayStatusTitle)
            }

            Text(signature.humanStatusMessage)
                .font(.footnote)
                .foregroundStyle(signature.requiresNewUpload ? .orange : .secondary)

            HStack(spacing: 10) {
                Label(signature.displayExpiration, systemImage: "calendar.badge.clock")
                if let days = signature.expiresInDays {
                    Text("\(days) días")
                }
            }
            .font(.caption)
            .foregroundStyle(signature.expiresSoon ? .orange : .secondary)

            HStack(spacing: 8) {
                if permissionSet.can(PermissionCatalog.signatureTest), signature.canValidate {
                    Button("Validar", action: onValidate)
                        .buttonStyle(.bordered)
                }

                if permissionSet.can(PermissionCatalog.signatureReplace), signature.canActivate {
                    Button("Activar", action: onActivate)
                        .buttonStyle(.borderedProminent)
                }

                if permissionSet.can(PermissionCatalog.signatureRevoke), signature.canRevoke {
                    Button("Revocar", role: .destructive, action: onRevoke)
                        .buttonStyle(.bordered)
                }
            }

            if let blockedHint = signature.blockedActionHint {
                Text(blockedHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SignatureActionSheetState: Identifiable {
    let signature: AdminElectronicSignature
    let kind: AdminElectronicSignaturesView.ActionKind

    var id: String { signature.id + String(describing: kind) }

    var title: String {
        switch kind {
        case .validate: return "Validar firma"
        case .activate: return "Activar firma"
        case .revoke: return "Revocar firma"
        }
    }

    var actionTitle: String {
        switch kind {
        case .validate: return "Validar"
        case .activate: return "Activar"
        case .revoke: return "Revocar"
        }
    }

    var isAllowed: Bool {
        switch kind {
        case .validate: return signature.canValidate
        case .activate: return signature.canActivate
        case .revoke: return signature.canRevoke
        }
    }

    var blockedMessage: String {
        switch kind {
        case .validate:
            return "Esta firma no está en un estado que permita validarla. Carga una nueva si está vencida, revocada o inválida."
        case .activate:
            return "Solo una firma válida puede activarse. Valídala primero o carga una nueva firma."
        case .revoke:
            return "Esta firma ya no puede revocarse desde este estado."
        }
    }
}

private struct UploadSignatureSheet: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let onClose: () -> Void

    @State private var alias = "Firma principal"
    @State private var selectedFileName = ""
    @State private var selectedFileData: Data?
    @State private var password = ""
    @State private var reason = ""
    @State private var showFileImporter = false
    @State private var fileImportError: String?

    private var canSubmit: Bool {
        !alias.trimmedForSignature.isEmpty
            && !selectedFileName.trimmedForSignature.isEmpty
            && selectedFileData?.isEmpty == false
            && !password.isEmpty
            && !reason.trimmedForSignature.isEmpty
            && !viewModel.isMutating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Archivo de firma") {
                    TextField("Alias", text: $alias)

                    Button {
                        showFileImporter = true
                    } label: {
                        Label(selectedFileName.isEmpty ? "Seleccionar archivo .p12/.pfx" : selectedFileName, systemImage: "doc.badge.gearshape")
                    }

                    if let selectedFileData {
                        Text("Archivo listo para enviar · \(selectedFileData.count) bytes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let fileImportError {
                        Text(fileImportError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    SecureField("Contraseña de la firma", text: $password)
                        .textContentType(.password)
                }

                Section("Seguridad") {
                    Text("La contraseña solo vive temporalmente en esta pantalla. No se muestra después, no se guarda en iOS y no se usa para firmar XML en el dispositivo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("El archivo y la contraseña se envían al backend por el canal seguro configurado para que el servidor valide y custodie la firma.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Motivo de auditoría") {
                    TextField("Ejemplo: carga inicial, renovación o firma vencida", text: $reason, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Cargar firma")
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: SignatureFileType.allowedContentTypes,
                allowsMultipleSelection: false,
                onCompletion: handleFileImporterResult
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        clearSensitiveState()
                        onClose()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isMutating ? "Subiendo…" : "Subir") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                }
            }
            .onDisappear(perform: clearSensitiveState)
        }
    }

    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        fileImportError = nil

        do {
            guard let url = try result.get().first else { return }
            guard SignatureFileType.isAllowed(fileName: url.lastPathComponent) else {
                selectedFileName = ""
                selectedFileData = nil
                fileImportError = "Selecciona un archivo .p12 o .pfx."
                return
            }

            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            guard !data.isEmpty else {
                selectedFileName = ""
                selectedFileData = nil
                fileImportError = "El archivo seleccionado está vacío."
                return
            }

            guard data.count <= SignatureFileType.maximumSizeInBytes else {
                selectedFileName = ""
                selectedFileData = nil
                fileImportError = "El archivo supera el tamaño máximo permitido para una firma."
                return
            }

            selectedFileName = url.lastPathComponent
            selectedFileData = data
        } catch {
            selectedFileName = ""
            selectedFileData = nil
            fileImportError = "No se pudo leer el archivo seleccionado."
        }
    }

    private func submit() async {
        guard let selectedFileData else { return }

        await viewModel.uploadSignature(
            alias: alias,
            fileName: selectedFileName,
            fileData: selectedFileData,
            password: password,
            reason: reason
        )

        if viewModel.errorMessage == nil {
            clearSensitiveState()
            onClose()
        } else {
            password = ""
        }
    }

    private func clearSensitiveState() {
        selectedFileName = ""
        selectedFileData = nil
        password = ""
        fileImportError = nil
    }
}

private enum SignatureFileType {
    static let maximumSizeInBytes = 10 * 1024 * 1024

    static var allowedContentTypes: [UTType] {
        [
            UTType(filenameExtension: "p12") ?? .data,
            UTType(filenameExtension: "pfx") ?? .data
        ]
    }

    static func isAllowed(fileName: String) -> Bool {
        let lowercased = fileName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lowercased.hasSuffix(".p12") || lowercased.hasSuffix(".pfx")
    }
}

private extension String {
    var trimmedForSignature: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
