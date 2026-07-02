//
//  AdminSupportDeskEntryPointView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Combine
import SwiftUI

struct AdminSupportDeskEntryPointView: View {
    private let notificationsRepository: (any AdminSupportRepository)?
    @StateObject private var notificationsViewModel = AdminSupportNotificationsViewModel()

    init(notificationsRepository: (any AdminSupportRepository)? = nil) {
        self.notificationsRepository = notificationsRepository
    }
    var body: some View {

        AdminSupportNotificationMiniBadge(
            unreadCount: notificationsViewModel.unreadCount,
            latestTitle: notificationsViewModel.latestTitle
        )
            .padding(.horizontal)
            .padding(.top, 8)
            .task {
                await notificationsViewModel.refreshIfNeeded(repository: notificationsRepository)
            }

        NavigationLink {
            AdminSupportDeskView(
                viewModel: AdminSupportDeskViewModel(
                    repository: RemoteAdminSupportTicketRepository()
                )
            )
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tickets de soporte")
                    .font(.headline)
                Text("Lista, detalle, contexto sanitizado, respuesta, nota interna y resolver/cerrar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("admin_support_desk_entrypoint")
    }
}

#Preview {
    NavigationStack {
        List {
            AdminSupportDeskEntryPointView()
        }
    }
}

private struct AdminSupportNotificationMiniBadge: View {
    let unreadCount: Int
    let latestTitle: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: unreadCount > 0 ? "bell.badge" : "bell")
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                Text(unreadCount > 0 ? "Novedades de soporte" : "Sin novedades de soporte")
                    .font(.subheadline.weight(.semibold))

                Text(latestTitle ?? "Las notificaciones internas aparecerán aquí.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                    .accessibilityLabel("Notificaciones no leídas: \(unreadCount)")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityIdentifier("adminSupportNotificationsBadge")
    }
}

@MainActor
private final class AdminSupportNotificationsViewModel: ObservableObject {
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var latestTitle: String?
    @Published private(set) var latestSummary: String?
    @Published private(set) var hasLoaded: Bool = false
    @Published private(set) var isLoading: Bool = false

    func refreshIfNeeded(repository: (any AdminSupportRepository)?) async {
        guard !hasLoaded else { return }
        await refresh(repository: repository)
    }

    func refresh(repository: (any AdminSupportRepository)?) async {
        guard !isLoading else { return }
        guard let repository else {
            hasLoaded = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await repository.getNotificationsSummary()
            unreadCount = max(0, response.unreadCount)
            latestTitle = response.items.first?.title
            latestSummary = response.items.first?.summary
            hasLoaded = true
        } catch {
            unreadCount = 0
            latestTitle = "Soporte no actualizado"
            latestSummary = "No se pudo consultar novedades ahora. Puedes intentar otra vez."
            hasLoaded = true
        }
    }
}
