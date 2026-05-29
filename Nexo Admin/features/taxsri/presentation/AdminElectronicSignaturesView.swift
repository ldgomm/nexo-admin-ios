//
//  AdminElectronicSignaturesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminElectronicSignaturesView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let permissions: Set<String>
    @State private var showUpload = false
    @State private var actionSignature: AdminElectronicSignature?
    @State private var actionKind: ActionKind?

    enum ActionKind { case validate, activate, revoke }

    var body: some View {
        AdminTaxSriSectionCard(title: "Firma electrónica", subtitle: "La app solo sube y muestra metadata segura; el backend custodia", systemImage: "signature") {
            if viewModel.signatures.isEmpty {
                Text("Aún no hay firmas electrónicas registradas.").foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.signatures) { signature in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(signature.alias).font(.subheadline.weight(.bold))
                                Text(signature.subject).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                            AdminTaxSriStatusBadge(text: signature.isActive ? "Activa" : signature.status)
                        }
                        HStack {
                            Label(signature.validTo ?? "Sin vencimiento", systemImage: "calendar.badge.clock")
                            if let days = signature.expiresInDays { Text("\(days) días") }
                        }
                        .font(.caption)
                        .foregroundStyle((signature.expiresInDays ?? 999) <= 30 ? .orange : .secondary)
                        HStack {
                            if PermissionSet(permissions).can(PermissionCatalog.signatureTest) {
                                Button("Validar") { actionSignature = signature; actionKind = .validate }.buttonStyle(.bordered)
                            }
                            if PermissionSet(permissions).can(PermissionCatalog.signatureReplace) && !signature.isActive {
                                Button("Activar") { actionSignature = signature; actionKind = .activate }.buttonStyle(.bordered)
                            }
                            if PermissionSet(permissions).can(PermissionCatalog.signatureRevoke) {
                                Button("Revocar", role: .destructive) { actionSignature = signature; actionKind = .revoke }.buttonStyle(.bordered)
                            }
                        }
                    }
                    Divider()
                }
            }
            if PermissionSet(permissions).can(PermissionCatalog.signatureUpload) {
                Button("Subir firma .p12/.pfx") { showUpload = true }.buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showUpload) { UploadSignatureSheet(viewModel: viewModel) { showUpload = false } }
        .sheet(item: Binding(get: { actionSignature.map { SignatureActionSheetState(signature: $0, kind: actionKind ?? .validate) } }, set: { _ in actionSignature = nil; actionKind = nil })) { state in
            AdminTaxSriReasonSheet(title: state.title, actionTitle: state.actionTitle, onCancel: { actionSignature = nil; actionKind = nil }) { reason in
                Task {
                    switch state.kind {
                    case .validate: await viewModel.validateSignature(id: state.signature.id, reason: reason)
                    case .activate: await viewModel.activateSignature(id: state.signature.id, reason: reason)
                    case .revoke: await viewModel.revokeSignature(id: state.signature.id, reason: reason)
                    }
                    actionSignature = nil; actionKind = nil
                }
            }
        }
    }
}

private struct SignatureActionSheetState: Identifiable {
    let signature: AdminElectronicSignature
    let kind: AdminElectronicSignaturesView.ActionKind
    var id: String { signature.id + String(describing: kind) }
    var title: String { kind == .validate ? "Validar firma" : kind == .activate ? "Activar firma" : "Revocar firma" }
    var actionTitle: String { kind == .validate ? "Validar" : kind == .activate ? "Activar" : "Revocar" }
}

private struct UploadSignatureSheet: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel
    let onClose: () -> Void
    @State private var alias = "Firma principal"
    @State private var fileName = "firma.p12"
    @State private var fileBase64 = ""
    @State private var password = ""
    @State private var reason = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Firma") {
                    TextField("Alias", text: $alias)
                    TextField("Nombre archivo .p12/.pfx", text: $fileName)
                    TextField("Contenido base64 temporal", text: $fileBase64, axis: .vertical).lineLimit(4, reservesSpace: true)
                    SecureField("Contraseña de la firma", text: $password)
                }
                Section("Seguridad") {
                    Text("La contraseña no debe persistirse en iOS. Se envía una sola vez al backend por HTTPS para validación/custodia segura.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Motivo") { TextField("Motivo de auditoría", text: $reason, axis: .vertical).lineLimit(3, reservesSpace: true) }
            }
            .navigationTitle("Subir firma")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onClose) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Subir") {
                        Task {
                            let data = Data(base64Encoded: fileBase64.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Data(fileBase64.utf8)
                            await viewModel.uploadSignature(alias: alias, fileName: fileName, fileData: data, password: password, reason: reason)
                            password = ""
                            onClose()
                        }
                    }.disabled(alias.isEmpty || fileName.isEmpty || password.isEmpty || reason.isEmpty)
                }
            }
        }
    }
}
