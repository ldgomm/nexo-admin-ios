//
//  AdminSupportDeskViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Combine
import Foundation

@MainActor
class AdminSupportDeskViewModel: ObservableObject {
    @Published private(set) var tickets: [AdminSupportTicketSummary] = []
    @Published private(set) var selectedTicket: AdminSupportTicketDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastTicketLoadSucceeded = false

    @Published var statusFilter: String?
    @Published var priorityFilter: String?
    @Published var organizationFilter: String?
    @Published var replyBody = ""
    @Published var internalNoteBody = ""

    private let repository: AdminSupportTicketRepository

    init(repository: AdminSupportTicketRepository = RemoteAdminSupportTicketRepository()) {
        self.repository = repository
    }

    func loadTickets() async {
        isLoading = true
        errorMessage = nil
        lastTicketLoadSucceeded = false
        defer { isLoading = false }

        let cleanStatus = statusFilter?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPriority = priorityFilter?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOrganization = organizationFilter?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let loadedTickets = try await repository.listTickets(
                status: cleanStatus?.isEmpty == true ? nil : cleanStatus,
                priority: cleanPriority?.isEmpty == true ? nil : cleanPriority,
                organizationId: cleanOrganization?.isEmpty == true ? nil : cleanOrganization
            )
            tickets = loadedTickets
            errorMessage = nil
            lastTicketLoadSucceeded = true
        } catch {
            tickets = []
            lastTicketLoadSucceeded = false
            errorMessage = Self.supportTicketErrorMessage(error)
        }
    }

    private static func supportTicketErrorMessage(_ error: Error) -> String {
        if let apiError = error as? AdminSupportTicketAPI.APIError {
            return apiError.userVisibleMessage
        }
        let detail = String(describing: error).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return "No se pudo cargar tickets de soporte." }
        return "No se pudo cargar tickets de soporte. Detalle: \(detail)"
    }

    func selectTicket(_ ticket: AdminSupportTicketSummary) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            selectedTicket = try await repository.getTicketDetail(ticketId: ticket.ticketId)
        } catch {
            errorMessage = "No se pudo cargar el detalle del ticket."
        }
    }

    func replyToTicket() async {
        guard let ticket = selectedTicket else { return }
        let body = replyBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        do {
            selectedTicket = try await repository.replyToTicket(ticketId: ticket.ticketId, body: body)
            replyBody = ""
        } catch {
            errorMessage = "No se pudo responder el ticket."
        }
    }

    func addInternalNote() async {
        guard let ticket = selectedTicket else { return }
        let body = internalNoteBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        do {
            selectedTicket = try await repository.addInternalNote(ticketId: ticket.ticketId, body: body)
            internalNoteBody = ""
        } catch {
            errorMessage = "No se pudo agregar la nota interna."
        }
    }

    func resolveTicket() async {
        await transitionTicket(targetStatus: "RESOLVED")
    }

    func closeTicket() async {
        await transitionTicket(targetStatus: "CLOSED")
    }

    private func transitionTicket(targetStatus: String) async {
        guard let ticket = selectedTicket else { return }

        do {
            selectedTicket = try await repository.transitionTicket(
                ticketId: ticket.ticketId,
                targetStatus: targetStatus
            )
        } catch {
            errorMessage = "No se pudo cambiar el estado del ticket."
        }
    }
}
