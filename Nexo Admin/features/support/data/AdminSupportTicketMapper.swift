//
//  AdminSupportTicketMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

enum AdminSupportTicketMapper {
    static func mapSummary(_ dto: AdminSupportTicketSummaryDTO) -> AdminSupportTicketSummary {
        AdminSupportTicketSummary(
            ticketId: dto.ticketId,
            organizationId: dto.organizationId,
            subject: dto.subject,
            status: dto.status,
            priority: dto.priority,
            requesterLabel: dto.requesterLabel,
            updatedAt: dto.updatedAt
        )
    }

    static func mapDetail(_ dto: AdminSupportTicketDetailDTO) -> AdminSupportTicketDetail {
        AdminSupportTicketDetail(
            ticketId: dto.ticketId,
            organizationId: dto.organizationId,
            subject: dto.subject,
            status: dto.status,
            priority: dto.priority,
            requesterLabel: dto.requesterLabel,
            contextRefs: dto.contextRefs.map(mapContext),
            messages: dto.messages.map(mapMessage),
            internalNotes: dto.internalNotes.map(mapInternalNote)
        )
    }

    private static func mapContext(_ dto: AdminSupportTicketContextDTO) -> AdminSupportTicketContextRef {
        let safeValue = dto.sanitizedDisplayValue ?? dto.value ?? "Contexto sanitizado sin valor visible"
        let contextId = dto.contextId ?? "\(dto.type)-\(dto.label)"
        return AdminSupportTicketContextRef(
            contextId: contextId,
            type: dto.type,
            label: dto.label,
            sanitizedDisplayValue: safeValue,
            redactionStatus: dto.redactionStatus
        )
    }

    private static func mapMessage(_ dto: AdminSupportTicketMessageDTO) -> AdminSupportTicketMessage {
        AdminSupportTicketMessage(
            messageId: dto.messageId,
            authorLabel: dto.authorLabel,
            body: dto.body,
            createdAt: dto.createdAt,
            internalOnly: dto.internalOnly
        )
    }

    private static func mapInternalNote(_ dto: AdminSupportInternalNoteDTO) -> AdminSupportInternalNote {
        AdminSupportInternalNote(
            noteId: dto.noteId,
            body: dto.body,
            createdAt: dto.createdAt,
            authorLabel: dto.authorLabel
        )
    }
}
