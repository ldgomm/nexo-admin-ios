//
//  AdminSupportTicketModels.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

struct AdminSupportTicketSummary: Identifiable, Equatable {
    var id: String { ticketId }

    let ticketId: String
    let organizationId: String
    let subject: String
    let status: String
    let priority: String
    let requesterLabel: String
    let updatedAt: String
}

struct AdminSupportTicketDetail: Identifiable, Equatable {
    var id: String { ticketId }

    let ticketId: String
    let organizationId: String
    let subject: String
    let status: String
    let priority: String
    let requesterLabel: String
    let contextRefs: [AdminSupportTicketContextRef]
    let messages: [AdminSupportTicketMessage]
    let internalNotes: [AdminSupportInternalNote]
}

struct AdminSupportTicketContextRef: Identifiable, Equatable {
    var id: String { contextId }

    let contextId: String
    let type: String
    let label: String
    let sanitizedDisplayValue: String
    let redactionStatus: String
}

struct AdminSupportTicketMessage: Identifiable, Equatable {
    var id: String { messageId }

    let messageId: String
    let authorLabel: String
    let body: String
    let createdAt: String
    let internalOnly: Bool
}

struct AdminSupportInternalNote: Identifiable, Equatable {
    var id: String { noteId }

    let noteId: String
    let body: String
    let createdAt: String
    let authorLabel: String
}
