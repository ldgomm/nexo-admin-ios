//
//  AdminSupplierStatementViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N — Permission-aware supplier statements and operational CSV exports.
//

import Combine
import Foundation

@MainActor
class AdminSupplierStatementViewModel: ObservableObject {
    @Published var supplierSearch = ""
    @Published var selectedSupplierId = "" {
        didSet {
            guard oldValue != selectedSupplierId else { return }
            clearStatement()
        }
    }
    @Published var branchId = "" { didSet { invalidateDownloadedFile(oldValue, branchId) } }
    @Published var currency = "USD" { didSet { invalidateDownloadedFile(oldValue, currency) } }
    @Published var from = "" { didSet { invalidateDownloadedFile(oldValue, from) } }
    @Published var to = "" { didSet { invalidateDownloadedFile(oldValue, to) } }
    @Published var asOf = "" { didSet { invalidateDownloadedFile(oldValue, asOf) } }

    @Published private(set) var suppliers: [AdminSupplier] = []
    @Published private(set) var lines: [AdminSupplierStatementLine] = []
    @Published private(set) var openingBalance: AdminProcurementMoney?
    @Published private(set) var closingBalance: AdminProcurementMoney?
    @Published private(set) var statementCurrency: String?
    @Published private(set) var statementFrom: String?
    @Published private(set) var statementTo: String?
    @Published private(set) var statementAsOf: String?
    @Published private(set) var hasMore = false
    @Published private(set) var isLoadingSuppliers = false
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isExporting = false
    @Published private(set) var downloadedFile: AdminProcurementDownloadedFile?
    @Published private(set) var errorMessage: String?
    @Published private(set) var infoMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var nextCursor: String?
    private var activeQuery: AdminSupplierStatementQuery?
    private var hasLoadedSuppliers = false

    init(
        repository: any AdminProcurementRepository,
        permissions: Set<String>,
        initialSupplier: AdminSupplier? = nil
    ) {
        self.repository = repository
        self.permissions = permissions
        if let initialSupplier {
            suppliers = [initialSupplier]
            selectedSupplierId = initialSupplier.id
            currency = initialSupplier.defaultCurrency
            hasLoadedSuppliers = true
        }
    }

    var canView: Bool { AdminSupplierStatementAccess.canView(permissions) }
    var canExport: Bool { AdminSupplierStatementAccess.canExport(permissions) }
    var canBrowseSuppliers: Bool { AdminSupplierStatementAccess.canBrowseSuppliers(permissions) }
    var canViewAudit: Bool { AdminSupplierStatementAccess.canViewAudit(permissions) }
    var canViewOperationalExports: Bool { AdminProcurementExportAccess.canViewCatalog(permissions) }

    lazy var operationalExportsViewModel = AdminProcurementExportsViewModel(
        repository: repository,
        permissions: permissions
    )

    var selectedSupplierName: String {
        suppliers.first(where: { $0.id == selectedSupplierId })?.displayName
            ?? "Proveedor seleccionado"
    }

    func loadSuppliersIfNeeded() async {
        guard !hasLoadedSuppliers else { return }
        await searchSuppliers()
    }

    func searchSuppliers() async {
        guard canBrowseSuppliers else {
            errorMessage = "Tu usuario necesita suppliers.view para seleccionar un proveedor desde Admin."
            return
        }
        guard !isLoadingSuppliers else { return }
        isLoadingSuppliers = true
        errorMessage = nil
        defer { isLoadingSuppliers = false }

        do {
            let page = try await repository.listSuppliers(
                query: AdminSupplierListQuery(
                    query: supplierSearch.trimmedOrNil,
                    status: .active,
                    category: nil,
                    limit: 100,
                    cursor: nil
                )
            )
            suppliers = page.suppliers.sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            hasLoadedSuppliers = true
            if selectedSupplierId.isEmpty, suppliers.count == 1 {
                selectedSupplierId = suppliers[0].id
            }
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func refresh() async {
        await load(reset: true)
    }

    func loadNextPageIfNeeded(currentLine: AdminSupplierStatementLine) async {
        guard currentLine.id == lines.last?.id, hasMore, nextCursor != nil else { return }
        await load(reset: false)
    }

    func exportCSV() async {
        guard canExport else {
            errorMessage = "Tu usuario no tiene permiso para exportar estados de cuenta."
            return
        }
        guard !isExporting else { return }
        guard let query = validatedQuery(cursor: nil) else { return }

        isExporting = true
        errorMessage = nil
        infoMessage = nil
        downloadedFile = nil
        defer { isExporting = false }

        do {
            let file = try await repository.downloadSupplierStatementCSV(query: query)
            guard file.exportType == "supplier_statement",
                  file.exportVersion == "27R.J.v1",
                  file.localURL.isFileURL,
                  file.sizeBytes > 0 else {
                throw AppError.decoding("El archivo de estado de cuenta no coincide con el contrato esperado.")
            }
            downloadedFile = file
            infoMessage = "CSV canónico listo para compartir."
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() {
        branchId = ""
        currency = "USD"
        from = ""
        to = ""
        asOf = ""
        clearStatement()
    }

    private func load(reset: Bool) async {
        guard canView else {
            errorMessage = "Tu usuario no tiene permiso para consultar estados de cuenta."
            return
        }
        guard !isLoading, !isLoadingMore else { return }

        let query: AdminSupplierStatementQuery
        if reset {
            guard let validated = validatedQuery(cursor: nil) else { return }
            clearStatement()
            query = validated
            activeQuery = validated
            isLoading = true
        } else {
            guard let activeQuery, let nextCursor else { return }
            query = AdminSupplierStatementQuery(
                supplierId: activeQuery.supplierId,
                branchId: activeQuery.branchId,
                currency: activeQuery.currency,
                from: activeQuery.from,
                to: activeQuery.to,
                asOf: activeQuery.asOf,
                limit: activeQuery.limit,
                cursor: nextCursor
            )
            isLoadingMore = true
        }

        errorMessage = nil
        infoMessage = nil
        defer {
            isLoading = false
            isLoadingMore = false
        }

        do {
            let statement = try await repository.getSupplierStatement(query: query)
            guard accepts(statement, query: query) else {
                throw AppError.decoding(
                    "El servidor devolvió un estado de cuenta de otro contexto; no se mezclaron saldos."
                )
            }

            if reset {
                lines = statement.lines
                openingBalance = statement.openingBalance
            } else {
                guard let currentClosing = closingBalance,
                      statement.openingBalance == currentClosing else {
                    throw AppError.decoding(
                        "La página siguiente no continúa desde el saldo final anterior; no se mezclaron movimientos."
                    )
                }
                try appendUnique(statement.lines)
            }
            closingBalance = statement.closingBalance
            statementCurrency = statement.currency
            statementFrom = statement.from
            statementTo = statement.to
            statementAsOf = statement.asOf
            nextCursor = statement.nextCursor
            hasMore = statement.hasMore
            infoMessage = lines.isEmpty ? "No hay movimientos para los filtros seleccionados." : nil
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    private func validatedQuery(cursor: String?) -> AdminSupplierStatementQuery? {
        guard canView else {
            errorMessage = "Tu usuario no tiene permiso para consultar estados de cuenta."
            return nil
        }
        guard let supplierId = selectedSupplierId.trimmedOrNil else {
            errorMessage = "Selecciona un proveedor antes de consultar."
            return nil
        }
        let normalized: (currency: String, from: String?, to: String?, asOf: String?)
        do {
            normalized = try AdminProcurementFilterValidation.normalized(
                currency: currency,
                from: from,
                to: to,
                asOf: asOf
            )
        } catch let validation as AdminProcurementFilterValidationError {
            errorMessage = validation.message
            return nil
        } catch {
            errorMessage = "Los filtros del estado de cuenta no son válidos."
            return nil
        }
        currency = normalized.currency
        return AdminSupplierStatementQuery(
            supplierId: supplierId,
            branchId: branchId.trimmedOrNil,
            currency: normalized.currency,
            from: normalized.from,
            to: normalized.to,
            asOf: normalized.asOf,
            limit: 100,
            cursor: cursor
        )
    }

    private func accepts(
        _ statement: AdminSupplierStatement,
        query: AdminSupplierStatementQuery
    ) -> Bool {
        guard statement.supplierId == query.supplierId,
              statement.branchId == query.branchId,
              statement.currency == query.currency,
              statement.from == query.from,
              statement.to == query.to else {
            return false
        }
        if let asOf = query.asOf, statement.asOf != asOf { return false }
        return true
    }

    private func appendUnique(_ page: [AdminSupplierStatementLine]) throws {
        var ids = Set(lines.map(\.id))
        guard page.allSatisfy({ ids.insert($0.id).inserted }) else {
            throw AppError.decoding(
                "La página siguiente repite movimientos ya cargados; no se alteró el estado de cuenta."
            )
        }
        lines.append(contentsOf: page)
    }

    private func clearStatement() {
        lines = []
        openingBalance = nil
        closingBalance = nil
        statementCurrency = nil
        statementFrom = nil
        statementTo = nil
        statementAsOf = nil
        nextCursor = nil
        hasMore = false
        activeQuery = nil
        downloadedFile = nil
        infoMessage = nil
    }

    private func invalidateDownloadedFile(_ oldValue: String, _ newValue: String) {
        guard oldValue != newValue else { return }
        downloadedFile = nil
    }
}

@MainActor
class AdminProcurementExportsViewModel: ObservableObject {
    @Published var branchId = "" { didSet { invalidateDownload(oldValue, branchId) } }
    @Published var supplierId = "" { didSet { invalidateDownload(oldValue, supplierId) } }
    @Published var category = "" { didSet { invalidateDownload(oldValue, category) } }
    @Published var catalogItemId = "" { didSet { invalidateDownload(oldValue, catalogItemId) } }
    @Published var paymentMethod = "" { didSet { invalidateDownload(oldValue, paymentMethod) } }
    @Published var attachmentSourceType = "" { didSet { invalidateDownload(oldValue, attachmentSourceType) } }
    @Published var currency = "USD" { didSet { invalidateDownload(oldValue, currency) } }
    @Published var from = "" { didSet { invalidateDownload(oldValue, from) } }
    @Published var to = "" { didSet { invalidateDownload(oldValue, to) } }
    @Published var asOf = "" { didSet { invalidateDownload(oldValue, asOf) } }

    @Published private(set) var reports: [AdminProcurementReportCatalogEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var exportingReportType: String?
    @Published private(set) var downloadedFile: AdminProcurementDownloadedFile?
    @Published private(set) var errorMessage: String?
    @Published private(set) var infoMessage: String?

    private let repository: any AdminProcurementRepository
    private let permissions: Set<String>
    private var hasLoaded = false

    init(repository: any AdminProcurementRepository, permissions: Set<String>) {
        self.repository = repository
        self.permissions = permissions
    }

    var canViewCatalog: Bool { AdminProcurementExportAccess.canViewCatalog(permissions) }
    var canExport: Bool { AdminProcurementExportAccess.canExport(permissions) }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refreshCatalog()
    }

    func refreshCatalog() async {
        guard canViewCatalog else {
            errorMessage = "Tu usuario no tiene permiso para consultar el catálogo de reportes."
            return
        }
        guard !isLoading else { return }
        isLoading = true
        reports = []
        downloadedFile = nil
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }

        do {
            let catalog = try await repository.getProcurementReportCatalog()
            reports = try validatedOperationalReports(catalog)
            hasLoaded = true
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func export(_ report: AdminProcurementReportCatalogEntry) async {
        guard canExport else {
            errorMessage = "Tu usuario no tiene permiso para exportar reportes operativos."
            return
        }
        guard exportingReportType == nil else { return }
        guard reports.contains(where: { $0.reportType == report.reportType }) else {
            errorMessage = "El reporte solicitado no pertenece al catálogo backend validado."
            return
        }
        let normalized: (currency: String, from: String?, to: String?, asOf: String?)
        do {
            normalized = try AdminProcurementFilterValidation.normalized(
                currency: currency,
                from: from,
                to: to,
                asOf: asOf
            )
        } catch let validation as AdminProcurementFilterValidationError {
            errorMessage = validation.message
            return
        } catch {
            errorMessage = "Los filtros de exportación no son válidos."
            return
        }

        currency = normalized.currency
        exportingReportType = report.reportType
        downloadedFile = nil
        errorMessage = nil
        infoMessage = nil
        defer { exportingReportType = nil }

        let query = AdminProcurementOperationalExportQuery(
            reportType: report.reportType,
            branchId: branchId.trimmedOrNil,
            supplierId: supplierId.trimmedOrNil,
            category: category.trimmedOrNil,
            catalogItemId: catalogItemId.trimmedOrNil,
            paymentMethod: paymentMethod.trimmedOrNil?.uppercased(),
            attachmentSourceType: attachmentSourceType.trimmedOrNil?.uppercased(),
            currency: normalized.currency,
            from: normalized.from,
            to: normalized.to,
            asOf: normalized.asOf
        )

        do {
            let file = try await repository.downloadOperationalReportCSV(query: query)
            guard file.exportType == report.reportType,
                  file.exportVersion == "27R.L.v1",
                  file.localURL.isFileURL,
                  file.sizeBytes > 0 else {
                throw AppError.decoding("El archivo no coincide con el reporte solicitado.")
            }
            downloadedFile = file
            infoMessage = "Reporte \(report.title) listo para compartir."
        } catch {
            errorMessage = error.userFriendlyMessage
        }
    }

    func clearFilters() {
        branchId = ""
        supplierId = ""
        category = ""
        catalogItemId = ""
        paymentMethod = ""
        attachmentSourceType = ""
        currency = "USD"
        from = ""
        to = ""
        asOf = ""
        downloadedFile = nil
        infoMessage = nil
    }

    private func validatedOperationalReports(
        _ catalog: AdminProcurementReportCatalog
    ) throws -> [AdminProcurementReportCatalogEntry] {
        guard catalog.contractVersion == 1, !catalog.accountingEntriesGenerated else {
            throw AppError.decoding("El catálogo de reportes no coincide con el contrato operativo aceptado.")
        }
        let operational = catalog.reports.filter { $0.reportType != "supplier_statement" }
        let expectedTypes = AdminProcurementReadinessEvaluator.requiredReportTypes
            .subtracting(["supplier_statement"])
        guard Set(operational.map(\.reportType)) == expectedTypes,
              operational.count == expectedTypes.count else {
            throw AppError.decoding("El catálogo no contiene exactamente los nueve reportes operativos esperados.")
        }
        guard operational.allSatisfy({ entry in
            entry.implementation == "27R.L.v1" &&
                entry.csvPath == "/api/v1/admin/procurement/reports/\(entry.reportType)/export.csv"
        }) else {
            throw AppError.decoding("Una ruta de exportación salió del contrato Admin aceptado.")
        }
        return operational.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private func invalidateDownload(_ oldValue: String, _ newValue: String) {
        guard oldValue != newValue else { return }
        downloadedFile = nil
    }
}

private struct AdminProcurementFilterValidationError: Error {
    let message: String
}

private enum AdminProcurementFilterValidation {
    static func normalized(
        currency: String,
        from: String,
        to: String,
        asOf: String
    ) throws -> (currency: String, from: String?, to: String?, asOf: String?) {
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalizedCurrency.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else {
            throw AdminProcurementFilterValidationError(
                message: "La moneda debe usar tres letras, por ejemplo USD."
            )
        }
        let normalizedFrom = from.trimmedOrNil
        let normalizedTo = to.trimmedOrNil
        let normalizedAsOf = asOf.trimmedOrNil
        for (value, label) in [(normalizedFrom, "inicial"), (normalizedTo, "final"), (normalizedAsOf, "de corte")] {
            if let value, !isValidDate(value) {
                throw AdminProcurementFilterValidationError(
                    message: "La fecha \(label) debe usar el formato AAAA-MM-DD."
                )
            }
        }
        if let normalizedFrom, let normalizedTo, normalizedFrom > normalizedTo {
            throw AdminProcurementFilterValidationError(
                message: "La fecha inicial no puede ser posterior a la final."
            )
        }
        if let normalizedTo, let normalizedAsOf, normalizedTo > normalizedAsOf {
            throw AdminProcurementFilterValidationError(
                message: "La fecha final no puede ser posterior a la fecha de corte."
            )
        }
        return (normalizedCurrency, normalizedFrom, normalizedTo, normalizedAsOf)
    }

    private static func isValidDate(_ raw: String) -> Bool {
        guard raw.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else {
            return false
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: raw) else { return false }
        return formatter.string(from: date) == raw
    }
}
