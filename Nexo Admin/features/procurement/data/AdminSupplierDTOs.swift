//
//  AdminSupplierDTOs.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.2 — Exact supplier master wire contracts.
//

import Foundation

struct AdminSupplierListRequestDTO: Equatable, Sendable {
    let query: String?
    let status: String?
    let category: String?
    let limit: Int
    let cursor: String?
}

struct AdminSupplierContactDTO: Decodable, Sendable {
    let id: String
    let name: String
    let role: String?
    let email: String?
    let phone: String?
    let isPrimary: Bool
    let notes: String?
}

struct AdminSupplierPaymentTermsDTO: Decodable, Sendable {
    let mode: String
    let netDays: Int?
    let label: String?
    let notes: String?
}

struct AdminSupplierDTO: Decodable, Sendable {
    let id: String
    let legalName: String
    let tradeName: String?
    let identificationType: String?
    let identificationNumber: String?
    let email: String?
    let phone: String?
    let address: String?
    let categories: Set<String>
    let contacts: [AdminSupplierContactDTO]?
    let paymentTerms: AdminSupplierPaymentTermsDTO
    let defaultCurrency: String
    let status: String
    let notes: String?
    let createdAt: String
    let createdBy: String
    let updatedAt: String
    let updatedBy: String
    let version: Int64
}

struct AdminSupplierListResponseDTO: Decodable, Sendable {
    let suppliers: [AdminSupplierDTO]
    let nextCursor: String?
    let hasMore: Bool
}

struct AdminSupplierResponseMetaDTO: Decodable, Sendable {
    let requestId: String?
    let idempotencyReplayed: Bool?
}

struct AdminSupplierEnvelopeDTO: Decodable, Sendable {
    let data: AdminSupplierDTO
    let meta: AdminSupplierResponseMetaDTO
}

struct AdminSupplierContactWriteRequestDTO: Encodable, Sendable {
    let id: String?
    let name: String
    let role: String?
    let email: String?
    let phone: String?
    let isPrimary: Bool
    let notes: String?
}

struct AdminSupplierPaymentTermsWriteRequestDTO: Encodable, Sendable {
    let mode: String
    let netDays: Int?
    let label: String?
    let notes: String?
}

struct AdminSupplierWriteRequestDTO: Encodable, Sendable {
    let legalName: String
    let tradeName: String?
    let identificationType: String?
    let identificationNumber: String?
    let email: String?
    let phone: String?
    let address: String?
    let categories: [String]
    let contacts: [AdminSupplierContactWriteRequestDTO]
    let paymentTerms: AdminSupplierPaymentTermsWriteRequestDTO
    let defaultCurrency: String
    let notes: String?
    let expectedVersion: Int64?
}

struct AdminSupplierStatusRequestDTO: Encodable, Sendable {
    let status: String
    let reason: String
    let expectedVersion: Int64
}
