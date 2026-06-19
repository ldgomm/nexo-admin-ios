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
    @Published private(set) var loadingAction: AdminElectronicDocumentAction?
    @Published var filter = AdminElectronicDocumentListFilter()
    @Published var selectedDocumentId: String?
    @Published var retryReason = "Reintento solicitado desde Admin iOS"
    @Published var emailReason = "Reenvío solicitado desde Admin iOS"
    @Published var rideRegenerationReason = "Regeneración de RIDE solicitada desde Admin iOS"
    @Published var recipientOverride = ""
    @Published var previewFile: AdminElectronicDocumentDownloadedFile?

    private let listDocuments: ListAdminElectronicDocumentsUseCase
    private let getDocument: GetAdminElectronicDocumentUseCase
    private let getTimelineUseCase: GetAdminElectronicDocumentTimelineUseCase
    private let retryReceptionUseCase: RetryAdminElectronicDocumentReceptionUseCase
    private let retryAuthorizationUseCase: RetryAdminElectronicDocumentAuthorizationUseCase
    private let resendEmailUseCase: ResendAdminElectronicDocumentEmailUseCase
    private let regenerateRideUseCase: RegenerateAdminElectronicDocumentRideUseCase
    private let repository: any AdminElectronicDocumentRepository
    private let permissions: PermissionSet

    init(repository: any AdminElectronicDocumentRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = PermissionSet(values: permissions)
        self.listDocuments = ListAdminElectronicDocumentsUseCase(repository: repository)
        self.getDocument = GetAdminElectronicDocumentUseCase(repository: repository)
        self.getTimelineUseCase = GetAdminElectronicDocumentTimelineUseCase(repository: repository)
        self.retryReceptionUseCase = RetryAdminElectronicDocumentReceptionUseCase(repository: repository)
        self.retryAuthorizationUseCase = RetryAdminElectronicDocumentAuthorizationUseCase(repository: repository)
        self.resendEmailUseCase = ResendAdminElectronicDocumentEmailUseCase(repository: repository)
        self.regenerateRideUseCase = RegenerateAdminElectronicDocumentRideUseCase(repository: repository)
    }

    var isPerformingAction: Bool { loadingAction != nil }

    var loadingActionTitle: String? { loadingAction?.title }

    func isLoadingAction(_ action: AdminElectronicDocumentAction) -> Bool {
        loadingAction == action
    }

    func visibleActions(on detail: AdminElectronicDocumentDetail) -> [AdminElectronicDocumentAction] {
        let supported: [AdminElectronicDocumentAction] = [
            .downloadRide,
            .downloadXml,
            .resendEmail,
            .retryReception,
            .retryAuthorization,
            .regenerateRide
        ]
        return supported.filter { canPerform($0, on: detail) }
    }

    var canViewDocuments: Bool {
        permissions.canAny([PermissionCatalog.documentsView, PermissionCatalog.reportsDocuments])
    }

    var canDownloadRide: Bool {
        permissions.canAny([PermissionCatalog.documentsDownloadPDF, PermissionCatalog.documentsDownloadRide, PermissionCatalog.taxManage])
    }

    var canDownloadXML: Bool {
        permissions.canAny([PermissionCatalog.documentsDownloadXML, PermissionCatalog.taxManage])
    }

    var canViewTimeline: Bool {
        permissions.canAny([PermissionCatalog.documentsViewTimeline, PermissionCatalog.taxManage])
    }

    var canViewSriErrors: Bool {
        permissions.canAny([PermissionCatalog.documentsViewSriErrors, PermissionCatalog.taxManage])
    }

    var canRetryReception: Bool {
        permissions.canAny(["documents.retry_reception", "documents.electronic_invoice.retry_reception", PermissionCatalog.taxManage])
    }

    var canRetryAuthorization: Bool {
        permissions.canAny([PermissionCatalog.documentsRetryAuthorization, "documents.electronic_invoice.retry_authorization", PermissionCatalog.taxManage])
    }

    var canRegenerateRide: Bool {
        permissions.canAny(["documents.regenerate_ride", "documents.electronic_invoice.regenerate_ride", PermissionCatalog.taxManage])
    }

    var canResendEmail: Bool {
        permissions.canAny([PermissionCatalog.documentsResendEmail, PermissionCatalog.taxManage])
    }

    var documents: [AdminElectronicDocumentSummary] {
        if case .loaded(let value) = documentsState { return value }
        return []
    }

    var selectedDetail: AdminElectronicDocumentDetail? {
        if case .loaded(let value) = selectedDetailState { return value }
        return nil
    }

    func canPerform(_ action: AdminElectronicDocumentAction, on detail: AdminElectronicDocumentDetail) -> Bool {
        guard detail.allows(action) else { return false }
        switch action {
        case .viewDetail:
            return canViewDocuments
        case .viewTimeline:
            return canViewTimeline
        case .downloadRide:
            return canDownloadRide && detail.artifacts.ride != nil
        case .downloadXml:
            return canDownloadXML && (detail.artifacts.authorizedXml != nil || detail.artifacts.signedXml != nil)
        case .retryReception:
            return canRetryReception && detail.retrySummary.canRetryReception
        case .retryAuthorization:
            return canRetryAuthorization && detail.retrySummary.canRetryAuthorization
        case .resendEmail:
            return canResendEmail && detail.retrySummary.canResendEmail
        case .regenerateRide:
            return canRegenerateRide && canRegenerateRideForCurrentBackendContract(detail)
        case .unknown:
            return false
        }
    }

    private func canRegenerateRideForCurrentBackendContract(_ detail: AdminElectronicDocumentDetail) -> Bool {
        detail.retrySummary.canRegenerateRide
    }

    private func regenerateRideUnavailableMessage(for detail: AdminElectronicDocumentDetail) -> String {
        if !detail.retrySummary.canRegenerateRide {
            return "La regeneración de RIDE no está disponible para este comprobante según el estado publicado por el backend."
        }

        return "No se pudo regenerar el RIDE en este momento. Actualiza el detalle del comprobante e inténtalo nuevamente."
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

    func applyFilters() async { await load() }

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

    func refreshSelectedTimeline() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard detail.allows(.viewTimeline) else {
            actionErrorMessage = "El timeline no está disponible para este comprobante."
            return
        }
        guard canViewTimeline else {
            actionErrorMessage = "No tienes permiso para consultar el timeline de comprobantes."
            return
        }
        await performAction(.viewTimeline) {
            let timeline = try await self.getTimelineUseCase.execute(documentId: id)
            if let detail = self.selectedDetail {
                self.selectedDetailState = .loaded(AdminElectronicDocumentDetail(
                    id: detail.id,
                    summary: detail.summary,
                    branchName: detail.branchName,
                    emissionPointName: detail.emissionPointName,
                    legalName: detail.legalName,
                    commercialName: detail.commercialName,
                    taxId: detail.taxId,
                    totals: detail.totals,
                    lines: detail.lines,
                    sri: detail.sri,
                    artifacts: detail.artifacts,
                    email: detail.email,
                    timeline: timeline,
                    errors: detail.errors,
                    warnings: detail.warnings,
                    availableActions: detail.availableActions,
                    retrySummary: detail.retrySummary
                ))
            }
            self.lastActionMessage = "Timeline actualizado."
        }
    }

    func retrySelectedReception() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.retryReception, on: detail) else {
            actionErrorMessage = "No puedes reintentar recepción en el estado actual."
            return
        }

        await performAction(.retryReception) {
            let result = try await self.retryReceptionUseCase.execute(documentId: id, reason: self.retryReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
            await self.load()
        }
    }

    func retrySelectedAuthorization() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.retryAuthorization, on: detail) else {
            actionErrorMessage = "No puedes reintentar autorización en el estado actual."
            return
        }

        await performAction(.retryAuthorization) {
            let result = try await self.retryAuthorizationUseCase.execute(documentId: id, reason: self.retryReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
            await self.load()
        }
    }

    func resendSelectedEmail() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.resendEmail, on: detail) else {
            actionErrorMessage = "No puedes reenviar email en el estado actual."
            return
        }

        let recipient = recipientOverride.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        await performAction(.resendEmail) {
            let result = try await self.resendEmailUseCase.execute(documentId: id, recipientOverride: recipient, reason: self.emailReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
        }
    }

    func regenerateSelectedRide() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.regenerateRide, on: detail) else {
            actionErrorMessage = regenerateRideUnavailableMessage(for: detail)
            return
        }

        await performAction(.regenerateRide) {
            let result = try await self.regenerateRideUseCase.execute(documentId: id, reason: self.rideRegenerationReason)
            self.lastActionMessage = result.message
            await self.loadDetail(id: id)
            await self.load()
        }
    }

    func prepareRideShare() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.downloadRide, on: detail) else {
            actionErrorMessage = "No puedes descargar o abrir el RIDE en el estado actual."
            return
        }

        await performAction(.downloadRide) {
            self.previewFile = try await self.repository.downloadRideFile(documentId: id)
        }
    }

    func prepareXmlShare() async {
        guard let id = selectedDocumentId, let detail = selectedDetail else { return }
        guard canPerform(.downloadXml, on: detail) else {
            actionErrorMessage = "No puedes descargar o abrir el XML en el estado actual."
            return
        }

        await performAction(.downloadXml) {
            self.previewFile = try await self.repository.downloadXmlFile(documentId: id, authorizedOnly: true)
        }
    }

    func dismissActionMessages() {
        lastActionMessage = nil
        actionErrorMessage = nil
    }

    private func performAction(_ actionKind: AdminElectronicDocumentAction, _ action: () async throws -> Void) async {
        guard loadingAction == nil else { return }
        loadingAction = actionKind
        actionErrorMessage = nil
        lastActionMessage = nil
        do {
            try await action()
        } catch {
            actionErrorMessage = error.userFriendlyMessage
        }
        loadingAction = nil
    }
}
