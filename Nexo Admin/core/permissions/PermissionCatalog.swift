//
//  PermissionCatalog.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum PermissionCatalog {
    static let all = "*"

    static let credentialsUsersView = "credentials.users.view"
    static let credentialsUsersCreate = "credentials.users.create"
    static let credentialsUsersInvite = "credentials.users.invite"
    static let credentialsUsersBlock = "credentials.users.block"
    static let credentialsUsersUnblock = "credentials.users.unblock"
    static let credentialsUsersResetPassword = "credentials.users.reset_password"
    static let credentialsRolesView = "credentials.roles.view"
    static let credentialsRolesManage = "credentials.roles.manage"
    static let credentialsSessionsRevoke = "credentials.sessions.revoke"

    static let organizationView = "organization.view"
    static let organizationUpdate = "organization.update"

    static let modulesView = "modules.view"
    static let modulesEnable = "modules.enable"
    static let modulesDisable = "modules.disable"
    static let modulesManage = "modules.manage"

    static let verticalsView = "verticals.view"
    static let verticalsActivate = "verticals.activate"
    static let verticalsDeactivate = "verticals.deactivate"
    static let verticalsReadinessView = "verticals.readiness.view"
    static let verticalsSeedApply = "verticals.seed.apply"

    static let activitiesView = "activities.view"
    static let activitiesCreate = "activities.create"
    static let activitiesUpdate = "activities.update"

    static let branchesView = "branches.view"
    static let branchesCreate = "branches.create"
    static let branchesUpdate = "branches.update"
    static let branchLocationView = "branch.location.view"
    static let branchLocationUpdate = "branch.location.update"

    static let businessHoursView = "business_hours.view"
    static let businessHoursUpdate = "business_hours.update"
    static let businessHoursPublicVisibilityUpdate = "business_hours.public_visibility.update"

    static let settingsBranchesView = "settings.branches.view"
    static let settingsBranchesManage = "settings.branches.manage"

    static let settingsEmissionPointsView = "settings.emission_points.view"
    static let settingsEmissionPointsManage = "settings.emission_points.manage"
    static let emissionPointsView = settingsEmissionPointsView
    static let emissionPointsManage = settingsEmissionPointsManage

    static let catalogManageMaster = "catalog.manage_master"
    static let catalogLocalView = "catalog.local.view"
    static let catalogLocalCopyFromMaster = "catalog.local.copy_from_master"
    static let catalogLocalUpdateLocalCopy = "catalog.local.update_local_copy"
    static let catalogLocalChangePrice = "catalog.local.change_price"
    static let catalogLocalChangeTaxProfile = "catalog.local.change_tax_profile"
    static let catalogLocalDisableLocalCopy = "catalog.local.disable_local_copy"
    static let catalogLocalRequestNewItem = "catalog.local.request_new_item"
    static let catalogPriceHistoryView = "catalog.price_history.view"
    static let catalogIdentifiersScan = "catalog.identifiers.scan"
    static let catalogMasterView = "catalog.master.view"

    static let catalogCopyFromMaster = catalogLocalCopyFromMaster
    static let catalogUpdateLocalCopy = catalogLocalUpdateLocalCopy
    static let catalogDisableLocalCopy = catalogLocalDisableLocalCopy
    static let catalogRequestNewItem = catalogLocalRequestNewItem
    static let catalogLocalManage = catalogLocalUpdateLocalCopy
    static let catalogMasterManage = catalogManageMaster

    static let customersView = "customers.view"
    static let customersCreate = "customers.create"
    static let customersUpdate = "customers.update"

    static let salesView = "sales.view"
    static let paymentsView = "payments.view"
    static let receivablesView = "receivables.view"

    static let cashView = "cash.view"
    static let cashSessionViewCurrent = "cash.session.view_current"
    static let cashSessionViewHistory = "cash.session.view_history"
    static let cashSessionOpen = "cash.session.open"
    static let cashSessionClose = "cash.session.close"

    static let cashViewCurrent = cashSessionViewCurrent
    static let cashViewHistory = cashSessionViewHistory

    static let documentsView = "documents.view"
    static let documentsDownloadPDF = "documents.download_pdf"
    static let documentsDownloadRide = "documents.download_ride"
    static let documentsDownloadXML = "documents.download_xml"
    static let documentsResendEmail = "documents.resend_email"
    static let documentsRetryAuthorization = "documents.retry_authorization"
    static let documentsViewTimeline = "documents.view_timeline"
    static let documentsViewSriErrors = "documents.view_sri_errors"

    static let documentsElectronicInvoiceView = "documents.electronic_invoice.view"
    static let documentsElectronicInvoiceList = "documents.electronic_invoice.list"
    static let documentsElectronicInvoiceDownloadXML = "documents.electronic_invoice.download_xml"
    static let documentsElectronicInvoiceDownloadRIDE = "documents.electronic_invoice.download_ride"
    static let documentsElectronicInvoiceEmail = "documents.electronic_invoice.email"
    static let documentsElectronicInvoiceViewErrors = "documents.electronic_invoice.view_errors"
    static let documentsElectronicInvoiceViewAudit = "documents.electronic_invoice.view_audit"
    static let documentsElectronicInvoiceHomologate = "documents.electronic_invoice.homologate"
    static let documentsElectronicInvoiceEnableProduction = "documents.electronic_invoice.enable_production"
    static let documentsElectronicInvoiceManageSettings = "documents.electronic_invoice.manage_settings"

    static let taxSettingsView = "tax.settings.view"
    static let taxSettingsUpdateOrganizationRegime = "tax.settings.update_organization_regime"
    static let taxProfilesAssignToItem = "tax.profiles.assign_to_item"
    static let taxProfilesView = "tax.profiles.view"
    static let taxProfilesManage = "tax.profiles.manage"
    static let taxManage = taxSettingsUpdateOrganizationRegime

    static let sriSettingsView = "sri.settings.view"
    static let sriSettingsManage = "sri.settings.manage"
    static let sriReadinessRun = "sri.readiness.run"
    static let sriHomologationRun = "sri.homologation.run"
    static let sriHomologationRunsView = "sri.homologation_runs.view"
    static let sriProductionRequest = "sri.production.request"

    static let electronicSignatureView = "electronic_signature.view"
    static let electronicSignatureUpload = "electronic_signature.upload"
    static let electronicSignatureValidate = "electronic_signature.validate"
    static let electronicSignatureActivate = "electronic_signature.activate"
    static let electronicSignatureRevoke = "electronic_signature.revoke"

    static let signatureViewMetadata = electronicSignatureView
    static let signatureUpload = electronicSignatureUpload
    static let signatureReplace = "signature.replace"
    static let signatureUploadLegacy = signatureReplace
    static let signatureRevoke = "signature.revoke"
    static let signatureTest = "signature.test"
    static let signatureUseForInvoicing = "signature.use_for_invoicing"
    static let signatureViewAudit = "signature.view_audit"

    static let reportsDashboardView = "reports.dashboard.view"
    static let reportsSalesView = "reports.sales.view"
    static let reportsCashView = "reports.cash.view"
    static let reportsTaxView = "reports.tax.view"
    static let reportsDocumentsView = "reports.documents.view"

    static let reportsToday = reportsDashboardView
    static let reportsSales = reportsSalesView
    static let reportsCash = reportsCashView
    static let reportsDocuments = reportsDocumentsView

    static let publicStorefrontView = "public_storefront.view"
    static let publicStorefrontManage = "public_storefront.manage"
    static let publicProjectionView = "public_projection.view"
    static let publicProjectionManage = "public_projection.manage"

    static let devicesView = "devices.view"
    static let devicesManage = "devices.manage"
    static let observabilityView = "observability.view"
    static let healthView = "health.view"
    static let auditView = "audit.view"
    static let supportView = "support.view"
    static let supportDiagnosticsView = "support.diagnostics.view"
}

struct PermissionSet: Equatable, Sendable {
    let values: Set<String>

    init(_ values: Set<String>) {
        self.values = values
    }

    init(values: Set<String>) {
        self.values = values
    }

    func can(_ permission: String) -> Bool {
        values.contains(PermissionCatalog.all) || values.contains(permission)
    }

    func canAny(_ permissions: Set<String>) -> Bool {
        values.contains(PermissionCatalog.all) || permissions.isEmpty || !values.isDisjoint(with: permissions)
    }
}
