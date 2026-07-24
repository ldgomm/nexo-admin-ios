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
    @Published private(set) var isRecoveringSessions: Bool = false
    @Published var errorMessage: String?
    @Published var maxSessionsMessage: String?
    @Published var lockedMessage: String?

    private let authCoordinator: AuthSessionCoordinator

    init(authCoordinator: AuthSessionCoordinator) {
        self.authCoordinator = authCoordinator
    }

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading &&
        !isRecoveringSessions
    }

    var canRecoverSessions: Bool {
        maxSessionsMessage != nil &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading &&
        !isRecoveringSessions
    }

    func login() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        maxSessionsMessage = nil
        lockedMessage = nil
        defer { isLoading = false }

        do {
            try await authCoordinator.login(email: email, password: password)
        } catch AppError.maxSessionsReached(let message) {
            maxSessionsMessage = message
        } catch AppError.accountLocked(let message) {
            lockedMessage = message
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func recoverSessionsAndLogin() async {
        guard canRecoverSessions else { return }
        isRecoveringSessions = true
        errorMessage = nil
        lockedMessage = nil
        defer { isRecoveringSessions = false }

        do {
            try await authCoordinator.recoverSessionsAndLogin(email: email, password: password)
            maxSessionsMessage = nil
        } catch AppError.accountLocked(let message) {
            lockedMessage = message
        } catch AppError.maxSessionsReached(let message) {
            maxSessionsMessage = message
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }
}
