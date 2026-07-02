//
//  AdminSupportTicketRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

protocol AdminSupportTicketRepository {
    func listTickets(
        status: String?,
        priority: String?,
        organizationId: String?
    ) async throws -> [AdminSupportTicketSummary]

    func getTicketDetail(ticketId: String) async throws -> AdminSupportTicketDetail

    func replyToTicket(ticketId: String, body: String) async throws -> AdminSupportTicketDetail

    func addInternalNote(ticketId: String, body: String) async throws -> AdminSupportTicketDetail

    func transitionTicket(ticketId: String, targetStatus: String) async throws -> AdminSupportTicketDetail
}

// Compile-safe local implementation for Preview and UI development only.
// Production/default wiring should use RemoteAdminSupportTicketRepository.
struct PreviewAdminSupportTicketRepository: AdminSupportTicketRepository {
    private let sampleTicketId = "ticket_smoke_admin_support_preview"

    func listTickets(
        status: String?,
        priority: String?,
        organizationId: String?
    ) async throws -> [AdminSupportTicketSummary] {
        [
            AdminSupportTicketSummary(
                ticketId: sampleTicketId,
                organizationId: organizationId?.isEmpty == false ? organizationId! : "org_altos_del_murco_staging",
                subject: "Ayuda con venta pendiente",
                status: status?.isEmpty == false ? status! : "OPEN",
                priority: priority?.isEmpty == false ? priority! : "NORMAL",
                requesterLabel: "Business staging",
                updatedAt: "preview"
            )
        ]
    }

    func getTicketDetail(ticketId: String) async throws -> AdminSupportTicketDetail {
        makeDetail(ticketId: ticketId, status: "OPEN")
    }

    func replyToTicket(ticketId: String, body: String) async throws -> AdminSupportTicketDetail {
        makeDetail(ticketId: ticketId, status: "IN_PROGRESS", reply: body)
    }

    func addInternalNote(ticketId: String, body: String) async throws -> AdminSupportTicketDetail {
        makeDetail(ticketId: ticketId, status: "IN_PROGRESS", note: body)
    }

    func transitionTicket(ticketId: String, targetStatus: String) async throws -> AdminSupportTicketDetail {
        makeDetail(ticketId: ticketId, status: targetStatus)
    }

    private func makeDetail(ticketId: String, status: String, reply: String? = nil, note: String? = nil) -> AdminSupportTicketDetail {
        AdminSupportTicketDetail(
            ticketId: ticketId,
            organizationId: "org_altos_del_murco_staging",
            subject: "Ayuda con venta pendiente",
            status: status,
            priority: "NORMAL",
            requesterLabel: "Business staging",
            contextRefs: [
                AdminSupportTicketContextRef(
                    contextId: "ctx_preview_sale",
                    type: "SALE",
                    label: "Venta relacionada",
                    sanitizedDisplayValue: "Venta pendiente — datos sensibles ocultos",
                    redactionStatus: "SANITIZED"
                )
            ],
            messages: [
                AdminSupportTicketMessage(
                    messageId: "msg_preview_1",
                    authorLabel: "Business staging",
                    body: "Necesito ayuda con esta operación.",
                    createdAt: "preview",
                    internalOnly: false
                ),
                AdminSupportTicketMessage(
                    messageId: "msg_preview_reply",
                    authorLabel: "Soporte Admin",
                    body: reply ?? "Respuesta de soporte pendiente.",
                    createdAt: "preview",
                    internalOnly: false
                )
            ],
            internalNotes: [
                AdminSupportInternalNote(
                    noteId: "note_preview_1",
                    body: note ?? "Nota interna de soporte.",
                    createdAt: "preview",
                    authorLabel: "Soporte Admin"
                )
            ]
        )
    }
}
