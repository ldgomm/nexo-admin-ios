//
//  RootView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct RootView: View {
    @ObservedObject var container: AppContainer

    var body: some View {
        Group {
            switch container.sessionStore.phase {
            case .restoring:
                LaunchLoadingView()

            case .unauthenticated:
                LoginView(
                    viewModel: LoginViewModel(authCoordinator: container.authCoordinator)
                )

            case .needsPasswordChange:
                MandatoryPasswordChangePlaceholderView(
                    onLogout: { Task { await container.authCoordinator.logout() } }
                )

            case .needsOrganization:
                OrganizationSelectorView(
                    viewModel: OrganizationSelectorViewModel(
                        sessionStore: container.sessionStore,
                        authCoordinator: container.authCoordinator
                    )
                )

            case .authenticated:
                AdminShellView(
                    sessionStore: container.sessionStore,
                    onLogout: { Task { await container.authCoordinator.logout() } }
                )

            case .failed(let message):
                SessionFailureView(
                    message: message,
                    retry: { Task { await container.authCoordinator.restoreSession() } },
                    logout: { Task { await container.authCoordinator.logout() } }
                )
            }
        }
        .animation(.snappy, value: container.sessionStore.phase)
    }
}

private struct LaunchLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparando Nexo Admin…")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SessionFailureView: View {
    let message: String
    let retry: () -> Void
    let logout: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.orange)
            Text("No se pudo restaurar la sesión")
                .font(.title2.bold())
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HPrimaryButton(title: "Reintentar", action: retry)
            Button("Cerrar sesión local", action: logout)
                .buttonStyle(.plain)
                .foregroundStyle(.red)
        }
        .padding(28)
    }
}

private struct MandatoryPasswordChangePlaceholderView: View {
    let onLogout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Cambio de contraseña requerido")
                .font(.title.bold())
            Text("El backend indicó que esta credencial debe cambiar su contraseña antes de continuar. El flujo completo entra en el siguiente corte del módulo Auth.")
                .foregroundStyle(.secondary)
            HPrimaryButton(title: "Cerrar sesión", action: onLogout)
        }
        .padding(28)
    }
}
