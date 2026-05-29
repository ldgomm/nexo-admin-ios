//
//  LoginView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    VStack(spacing: 12) {
                        HTextField(
                            title: "Correo del administrador",
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                            textContentType: .username
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                        HSecureField(title: "Contraseña", text: $viewModel.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { submit() }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.vertical, 4)
                    }

                    HPrimaryButton(
                        title: "Ingresar",
                        isLoading: viewModel.isLoading,
                        action: submit
                    )
                    .disabled(!viewModel.canSubmit)

                    securityNote
                }
                .padding(NexoTheme.screenPadding)
            }
            .navigationTitle("Nexo Admin")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(Color.accentColor)

            Text("Administra tu negocio")
                .font(.largeTitle.bold())

            Text("Inicia sesión para revisar ventas, caja, catálogo, configuración y comprobantes desde tu iPhone.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
    }

    private var securityNote: some View {
        HCard {
            Label("Sesión protegida", systemImage: "lock.shield.fill")
                .font(.headline)
            Text("Los tokens se guardan en Keychain. La app no almacena contraseñas ni firma comprobantes en el dispositivo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func submit() {
        Task { await viewModel.login() }
    }
}
