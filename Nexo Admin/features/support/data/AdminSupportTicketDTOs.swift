//
//  AdminSupportTicketDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

struct AdminSupportTicketSummaryDTO: Decodable {
    let ticketId: String
    let organizationId: String
    let subject: String
    let status: String
    let priority: String
    let requesterLabel: String
    let updatedAt: String
}

struct AdminSupportTicketDetailDTO: Decodable {
    let ticketId: String
    let organizationId: String
    let subject: String
    let status: String
    let priority: String
    let requesterLabel: String
    let contextRefs: [AdminSupportTicketContextDTO]
    let messages: [AdminSupportTicketMessageDTO]
    let internalNotes: [AdminSupportInternalNoteDTO]
}

struct AdminSupportTicketContextDTO: Decodable {
    let contextId: String?
    let type: String
    let label: String
    let sanitizedDisplayValue: String?
    let redactionStatus: String
    let value: String?
}

struct AdminSupportTicketMessageDTO: Decodable {
    let messageId: String
    let authorLabel: String
    let body: String
    let createdAt: String
    let internalOnly: Bool
}

struct AdminSupportInternalNoteDTO: Decodable {
    let noteId: String
    let body: String
    let createdAt: String
    let authorLabel: String
}

struct AdminSupportReplyRequestDTO: Encodable {
    let body: String
}

struct AdminSupportInternalNoteRequestDTO: Encodable {
    let body: String
}

struct AdminSupportTransitionRequestDTO: Encodable {
    let targetStatus: String
}
