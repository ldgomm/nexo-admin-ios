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
    private let ticketRepository: (any AdminSupportTicketRepository)?
    @StateObject private var notificationsViewModel = AdminSupportNotificationsViewModel()

    init(
        notificationsRepository: (any AdminSupportRepository)? = nil,
        ticketRepository: (any AdminSupportTicketRepository)? = nil
    ) {
        self.notificationsRepository = notificationsRepository
        if let ticketRepository {
            self.ticketRepository = ticketRepository
        } else if let remoteRepository = notificationsRepository as? RemoteAdminSupportRepository {
            self.ticketRepository = remoteRepository.makeSupportTicketRepository()
        } else {
            self.ticketRepository = nil
        }
    }

    var body: some View {
        NavigationLink {
            AdminSupportDeskView(
                viewModel: AdminSupportDeskViewModel(
                    repository: ticketRepository ?? RemoteAdminSupportTicketRepository()
                )
            )
        } label: {
            AdminSupportDeskEntryCard(
                unreadCount: notificationsViewModel.unreadCount,
                latestTitle: notificationsViewModel.latestTitle
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityIdentifier("admin_support_desk_entrypoint")
        .task {
            await notificationsViewModel.refreshIfNeeded(repository: notificationsRepository)
        }
    }
}

private struct AdminSupportDeskEntryCard: View {
    let unreadCount: Int
    let latestTitle: String?

    private var hasUnread: Bool { unreadCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider().opacity(0.7)

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "ticket")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30, height: 30)
                    .background {
                        Circle().fill(Color.accentColor.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Tickets de soporte")
                        .font(.headline)

                    Text("Bandeja, contexto sanitizado, respuesta, nota interna y cierre.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.045), radius: 10, x: 0, y: 5)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasUnread ? "bell.badge.fill" : "bell")
                .font(.title3.weight(.semibold))
                .foregroundStyle(hasUnread ? Color.accentColor : Color.secondary)
                .frame(width: 34, height: 34)
                .background {
                    Circle()
                        .fill((hasUnread ? Color.accentColor : Color.secondary).opacity(0.12))
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(hasUnread ? "Soporte requiere atención" : "Soporte sin novedades")
                        .font(.subheadline.weight(.semibold))

                    if hasUnread {
                        Text("\(unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(Color.accentColor.opacity(0.14))
                            }
                            .accessibilityLabel("Notificaciones no leídas: \(unreadCount)")
                    }
                }

                Text(latestTitle ?? "Las notificaciones internas aparecerán aquí.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityIdentifier("adminSupportNotificationsBadge")
    }
}

@MainActor
private class AdminSupportNotificationsViewModel: ObservableObject {
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
