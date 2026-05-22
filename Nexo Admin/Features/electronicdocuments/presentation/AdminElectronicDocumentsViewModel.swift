//
//  AdminElectronicDocumentsViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminElectronicDocumentsViewModel: ObservableObject {
    @Published private(set) var documentsState: LoadableViewState<[AdminElectronicDocumentSummary]> = .idle
    @Published private(set) var selectedDetailState: LoadableViewState<AdminElectronicDocumentDetail> = .idle
    @Published private(set) var lastActionMessage: String?
    @Published private(set) var actionErrorMessage: String?
    @Published private(set) var isPerformingAction = false
    @Published var filter = AdminElectronicDocumentListFilter()
    @Published var selectedDocumentId: String?
    @Published var retryReason = "Reintento solicitado desde Admin iOS"
    @Published var emailReason = "Reenvío solicitado desde Admin iOS"
    @Published var recipientOverride = ""
    @Published var artifactToShare: AdminDocumentArtifact?

    private let listDocuments: ListAdminElectronicDocumentsUseCase
    private let getDocument: GetAdminElectronicDocumentUseCase
    private let retryAuthorizationUseCase: RetryAdminElectronicDocumentAuthorizationUseCase
    private let resendEmailUseCase: ResendAdminElectronicDocumentEmailUseCase
    private let repository: any AdminElectronicDocumentRepository
    private let permissions: PermissionSet

    init(
        repository: any AdminElectronicDocumentRepository,
        permissions: Set<String>
    ) {
        self.repository = repository
        self.permissions = PermissionSet(values: permissions)
        self.listDocuments = ListAdminElectronicDocumentsUseCase(repository: repository)
        self.getDocument = GetAdminElectronicDocumentUseCase(repository: repository)
        self.retryAuthorizationUseCase = RetryAdminElectronicDocumentAuthorizationUseCase(repository: repository)
        self.resendEmailUseCase = ResendAdminElectronicDocumentEmailUseCase(repository: repository)
    }

    var canViewDocuments: Bool {
        permissions.canAny([PermissionCatalog.documentsView, PermissionCatalog.reportsDocuments])
    }

    var canDownloadRide: Bool {
        permissions.canAny([PermissionCatalog.documentsDownloadPDF, PermissionCatalog.documentsDownloadRide])
    }

    var canDownloadXML: Bool {
        permissions.canAny([PermissionCatalog.documentsDownloadXML])
    }

    var canRetryAuthorization: Bool {
        permissions.canAny([PermissionCatalog.documentsRetryAuthorization, PermissionCatalog.taxManage])
    }

    var canResendEmail: Bool {
        permissions.canAny([PermissionCatalog.documentsResendEmail, PermissionCatalog.documentsView])
    }

    var documents: [AdminElectronicDocumentSummary] {
        if case .loaded(let value) = documentsState { return value }
        return []
    }

    var selectedDetail: AdminElectronicDocumentDetail? {
        if case .loaded(let value) = selectedDetailState { return value }
        return nil
    }

    func load() async {
        guard canViewDocuments else {
            documentsState = .failed("No tienes permiso para consultar comprobantes.")
            return
        }

        documentsState = .loading
        do {
            let result = try await listDocuments.execute(filter: filter)
            documentsState = result.documents.isEmpty
                ? .empty(filter.hasActiveFilters ? "No hay comprobantes con estos filtros." : "Todavía no hay comprobantes electrónicos emitidos.")
                : .loaded(result.documents)
        } catch {
            documentsState = .failed(error.userFriendlyMessage)
        }
    }

    func refresh() async {
        await load()
        if let selectedDocumentId {
            await loadDetail(id: selectedDocumentId)
        }
    }

    func applyFilters() async {
        await load()
    }

    func clearFilters() async {
        filter = AdminElectronicDocumentListFilter()
        await load()
    }

    func select(document: AdminElectronicDocumentSummary) async {
        selectedDocumentId = document.id
        await loadDetail(id: document.id)
    }

    func loadDetail(id: String) async {
        selectedDetailState = .loading
        do {
            selectedDetailState = .loaded(try await getDocument.execute(id: id))
        } catch {
            selectedDetailState = .failed(error.userFriendlyMessage)
        }
    }

    func retrySelectedAuthorization() async {
        guard let id = selectedDocumentId else { return }
        guard canRetryAuthorization else {
            actionErrorMessage = "No tienes permiso para reintentar autorización."
            return
        }

        await performAction {
            let result = try await self.retryAuthorizationUseCase.execute(documentId: id, reason: self.retryReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
            await self.load()
        }
    }

    func resendSelectedEmail() async {
        guard let id = selectedDocumentId else { return }
        guard canResendEmail else {
            actionErrorMessage = "No tienes permiso para reenviar email."
            return
        }

        let recipient = recipientOverride.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        await performAction {
            let result = try await self.resendEmailUseCase.execute(documentId: id, recipientOverride: recipient, reason: self.emailReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
        }
    }

    func prepareRideShare() async {
        guard let id = selectedDocumentId else { return }
        guard canDownloadRide else {
            actionErrorMessage = "No tienes permiso para descargar o compartir RIDE."
            return
        }

        await performAction {
            self.artifactToShare = try await self.repository.getRideArtifact(documentId: id)
            self.lastActionMessage = "RIDE listo para compartir."
        }
    }

    func prepareXmlShare() async {
        guard let id = selectedDocumentId else { return }
        guard canDownloadXML else {
            actionErrorMessage = "No tienes permiso para descargar XML."
            return
        }

        await performAction {
            self.artifactToShare = try await self.repository.getXmlArtifact(documentId: id, authorizedOnly: true)
            self.lastActionMessage = "XML autorizado listo para compartir."
        }
    }

    func dismissActionMessages() {
        lastActionMessage = nil
        actionErrorMessage = nil
    }

    private func performAction(_ action: () async throws -> Void) async {
        isPerformingAction = true
        actionErrorMessage = nil
        lastActionMessage = nil
        do {
            try await action()
        } catch {
            actionErrorMessage = error.userFriendlyMessage
        }
        isPerformingAction = false
    }
}
