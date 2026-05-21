//
//  LoginViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authCoordinator: AuthSessionCoordinator

    init(authCoordinator: AuthSessionCoordinator) {
        self.authCoordinator = authCoordinator
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty && !isLoading
    }

    func login() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authCoordinator.login(email: email, password: password)
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }
}
