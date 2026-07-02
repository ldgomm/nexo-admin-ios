//
//  RemoteAdminSupportTicketRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import Foundation

final class RemoteAdminSupportTicketRepository: AdminSupportTicketRepository {
    private let api: AdminSupportTicketAPI

    init(api: AdminSupportTicketAPI = AdminSupportTicketAPI()) {
        self.api = api
    }

    func listTickets(
        status: String?,
        priority: String?,
        organizationId: String?
    ) async throws -> [AdminSupportTicketSummary] {
        let dto = try await api.listTickets(status: status, priority: priority, organizationId: organizationId)
        return dto.map(AdminSupportTicketMapper.mapSummary)
    }

    func getTicketDetail(ticketId: String) async throws -> AdminSupportTicketDetail {
        let dto = try await api.getTicketDetail(ticketId: ticketId)
        return AdminSupportTicketMapper.mapDetail(dto)
    }

    func replyToTicket(ticketId: String, body: String) async throws -> AdminSupportTicketDetail {
        let dto = try await api.replyToTicket(ticketId: ticketId, body: body)
        return AdminSupportTicketMapper.mapDetail(dto)
    }

    func addInternalNote(ticketId: String, body: String) async throws -> AdminSupportTicketDetail {
        let dto = try await api.addInternalNote(ticketId: ticketId, body: body)
        return AdminSupportTicketMapper.mapDetail(dto)
    }

    func transitionTicket(ticketId: String, targetStatus: String) async throws -> AdminSupportTicketDetail {
        let dto = try await api.transitionTicket(ticketId: ticketId, targetStatus: targetStatus)
        return AdminSupportTicketMapper.mapDetail(dto)
    }
}
