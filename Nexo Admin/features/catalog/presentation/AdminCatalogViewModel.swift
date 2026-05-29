//
//  AdminCatalogViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class AdminCatalogViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var isSearchingMaster = false
    @Published private(set) var isSaving = false
    @Published private(set) var localItems: [AdminCatalogLocalItem] = []
    @Published private(set) var masterTemplates: [AdminCatalogMasterTemplate] = []
    @Published private(set) var requests: [AdminCatalogRequest] = []
    @Published private(set) var selectedItem: AdminCatalogLocalItem?
    @Published private(set) var selectedTemplate: AdminCatalogMasterTemplate?
    @Published private(set) var selectedRequest: AdminCatalogRequest?
    @Published private(set) var priceHistory: [AdminCatalogPriceHistoryEntry] = []

    @Published var localSearch = AdminCatalogSearchInput()
    @Published var masterSearch = AdminCatalogSearchInput()
    @Published var requestSearch = AdminCatalogSearchInput(limit: 100)
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let loadHome: LoadAdminCatalogHomeUseCase
    private let searchLocalItems: SearchAdminCatalogLocalItemsUseCase
    private let getLocalItem: GetAdminCatalogLocalItemUseCase
    private let updateLocalItem: UpdateAdminCatalogLocalItemUseCase
    private let changeLocalItemStatus: ChangeAdminCatalogLocalItemStatusUseCase
    private let searchMasterTemplates: SearchAdminCatalogMasterTemplatesUseCase
    private let getMasterTemplate: GetAdminCatalogMasterTemplateUseCase
    private let copyTemplateUseCase: CopyAdminCatalogTemplateUseCase
    private let listRequests: ListAdminCatalogRequestsUseCase
    private let createRequestUseCase: CreateAdminCatalogRequestUseCase
    private let listPriceHistory: ListAdminCatalogPriceHistoryUseCase

    init(repository: any AdminCatalogRepository) {
        self.loadHome = LoadAdminCatalogHomeUseCase(repository: repository)
        self.searchLocalItems = SearchAdminCatalogLocalItemsUseCase(repository: repository)
        self.getLocalItem = GetAdminCatalogLocalItemUseCase(repository: repository)
        self.updateLocalItem = UpdateAdminCatalogLocalItemUseCase(repository: repository)
        self.changeLocalItemStatus = ChangeAdminCatalogLocalItemStatusUseCase(repository: repository)
        self.searchMasterTemplates = SearchAdminCatalogMasterTemplatesUseCase(repository: repository)
        self.getMasterTemplate = GetAdminCatalogMasterTemplateUseCase(repository: repository)
        self.copyTemplateUseCase = CopyAdminCatalogTemplateUseCase(repository: repository)
        self.listRequests = ListAdminCatalogRequestsUseCase(repository: repository)
        self.createRequestUseCase = CreateAdminCatalogRequestUseCase(repository: repository)
        self.listPriceHistory = ListAdminCatalogPriceHistoryUseCase(repository: repository)
    }

    var activeItemsCount: Int { localItems.filter(\.isActive).count }
    var pausedItemsCount: Int { localItems.filter { $0.status.uppercased() == "PAUSED" }.count }
    var pendingRequestsCount: Int { requests.filter { $0.status.uppercased() == "PENDING" || $0.status.uppercased() == "NEEDS_MORE_INFO" }.count }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let summary = try await loadHome.execute(search: localSearch)
            localItems = summary.localItems
            requests = summary.requests
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func refresh() async {
        await load()
    }

    func searchLocal() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            localItems = try await searchLocalItems.execute(search: localSearch)
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func searchMaster() async {
        guard !isSearchingMaster else { return }
        isSearchingMaster = true
        errorMessage = nil
        defer { isSearchingMaster = false }

        do {
            masterTemplates = try await searchMasterTemplates.execute(search: masterSearch)
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func reloadRequests() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            requests = try await listRequests.execute(search: requestSearch)
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func selectItem(_ item: AdminCatalogLocalItem, organizationId: String?) async {
        selectedItem = item
        priceHistory = []
        do {
            selectedItem = try await getLocalItem.execute(id: item.id)
            if let organizationId = organizationId?.trimmedOrNil {
                priceHistory = try await listPriceHistory.execute(organizationId: organizationId, itemId: item.id, limit: 25)
            }
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func selectTemplate(_ template: AdminCatalogMasterTemplate) async {
        selectedTemplate = template
        do {
            selectedTemplate = try await getMasterTemplate.execute(id: template.id)
        } catch {
            errorMessage = error.userFacingMessage
        }
    }

    func selectRequest(_ request: AdminCatalogRequest) async {
        selectedRequest = request
    }

    func updateItem(_ input: SaveAdminCatalogLocalItemInput) async -> Bool {
        guard validateReason(input.reason) else { return false }
        return await savingSuccess("Ítem de catálogo actualizado.") {
            let updated = try await updateLocalItem.execute(input)
            replaceLocalItem(updated)
            selectedItem = updated
            if input.localPrice != nil {
                priceHistory = []
            }
        }
    }

    func activateItem(_ item: AdminCatalogLocalItem, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Ítem activado.") {
            let updated = try await changeLocalItemStatus.activate(id: item.id, reason: reason)
            replaceLocalItem(updated)
            selectedItem = updated
        }
    }

    func deactivateItem(_ item: AdminCatalogLocalItem, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Ítem desactivado.") {
            let updated = try await changeLocalItemStatus.deactivate(id: item.id, reason: reason)
            replaceLocalItem(updated)
            selectedItem = updated
        }
    }

    func removeItem(_ item: AdminCatalogLocalItem, reason: String) async -> Bool {
        guard validateReason(reason) else { return false }
        return await savingSuccess("Copia local removida.") {
            let updated = try await changeLocalItemStatus.remove(id: item.id, reason: reason)
            replaceLocalItem(updated)
            selectedItem = updated
        }
    }

    func copyTemplate(_ input: CopyAdminCatalogTemplateInput) async -> Bool {
        guard validateRequired(input.templateId, "Selecciona una plantilla."), validateRequired(input.activityId, "Ingresa la actividad."), validateRequired(input.taxProfileCode, "Ingresa el tax profile."), validateReason(input.reason) else { return false }
        return await savingSuccess("Plantilla copiada al catálogo local.") {
            let item = try await copyTemplateUseCase.execute(input)
            localItems.insert(item, at: 0)
        }
    }

    func createRequest(_ input: CreateAdminCatalogRequestInput) async -> Bool {
        guard validateRequired(input.requestedName, "Ingresa el nombre solicitado."), validateRequired(input.requestedType, "Selecciona el tipo." ) else { return false }
        return await savingSuccess("Solicitud de catálogo creada.") {
            let request = try await createRequestUseCase.execute(input)
            requests.insert(request, at: 0)
        }
    }

    private func replaceLocalItem(_ item: AdminCatalogLocalItem) {
        if let index = localItems.firstIndex(where: { $0.id == item.id }) {
            localItems[index] = item
        } else {
            localItems.insert(item, at: 0)
        }
    }

    private func savingSuccess(_ message: String, operation: () async throws -> Void) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            try await operation()
            successMessage = message
            return true
        } catch {
            errorMessage = error.userFacingMessage
            return false
        }
    }

    private func validateReason(_ reason: String) -> Bool {
        validateRequired(reason, "Ingresa un motivo para auditar este cambio.")
    }

    private func validateRequired(_ value: String, _ message: String) -> Bool {
        if value.trimmedOrNil == nil {
            errorMessage = message
            return false
        }
        return true
    }
}

private extension Error {
    var userFacingMessage: String {
        if let appError = self as? AppError { return appError.localizedDescription }
        return localizedDescription
    }
}
