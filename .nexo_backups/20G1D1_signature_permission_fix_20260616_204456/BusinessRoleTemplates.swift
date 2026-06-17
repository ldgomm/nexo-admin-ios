//
//  BusinessRoleTemplates.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import Foundation

enum BusinessRoleTemplate: String, CaseIterable, Identifiable, Sendable {
    case owner
    case operationsAdmin
    case supervisor
    case cashier
    case seller
    case readOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Dueño"
        case .operationsAdmin: return "Administrador operativo"
        case .supervisor: return "Supervisor"
        case .cashier: return "Cajero"
        case .seller: return "Vendedor"
        case .readOnly: return "Solo consulta"
        }
    }

    var code: String {
        switch self {
        case .owner: return "owner_operativo"
        case .operationsAdmin: return "administrador_operativo"
        case .supervisor: return "supervisor"
        case .cashier: return "cajero"
        case .seller: return "vendedor"
        case .readOnly: return "solo_consulta"
        }
    }

    var description: String {
        switch self {
        case .owner:
            return "Acceso operativo completo del negocio, incluyendo ventas, caja, reportes, clientes, documentos, catálogo local, impuestos y administración de usuarios. No usa wildcard."
        case .operationsAdmin:
            return "Opera ventas, cobros, caja, reportes, clientes, documentos e inventario básico sin tocar credenciales críticas ni firma electrónica."
        case .supervisor:
            return "Supervisa ventas, caja actual, reportes, historial, clientes, documentos e inventario de consulta."
        case .cashier:
            return "Abre y cierra caja, registra ventas, cobra, consulta caja actual y revisa ventas del día."
        case .seller:
            return "Crea y confirma ventas, consulta clientes básicos e historial operativo limitado."
        case .readOnly:
            return "Consulta usuarios operativos, ventas, caja, reportes, clientes, documentos e inventario sin permisos de mutación."
        }
    }

    var defaultReason: String {
        "Crear rol \(title) desde plantilla 17G para operación Business"
    }

    var permissionKeys: Set<String> {
        switch self {
        case .owner:
            return [
                PermissionCatalog.credentialsUsersView,
                PermissionCatalog.credentialsUsersCreate,
                PermissionCatalog.credentialsUsersInvite,
                PermissionCatalog.credentialsUsersBlock,
                PermissionCatalog.credentialsUsersUnblock,
                PermissionCatalog.credentialsUsersResetPassword,
                PermissionCatalog.credentialsRolesView,
                PermissionCatalog.credentialsRolesManage,
                PermissionCatalog.credentialsSessionsRevoke,
                PermissionCatalog.organizationView,
                PermissionCatalog.organizationUpdate,
                PermissionCatalog.modulesView,
                PermissionCatalog.modulesManage,
                PermissionCatalog.activitiesView,
                PermissionCatalog.activitiesCreate,
                PermissionCatalog.activitiesUpdate,
                PermissionCatalog.branchesView,
                PermissionCatalog.branchesCreate,
                PermissionCatalog.branchesUpdate,
                PermissionCatalog.settingsBranchesView,
                PermissionCatalog.settingsBranchesManage,
                PermissionCatalog.settingsEmissionPointsView,
                PermissionCatalog.settingsEmissionPointsManage,
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.catalogLocalCopyFromMaster,
                PermissionCatalog.catalogLocalUpdateLocalCopy,
                PermissionCatalog.catalogLocalChangePrice,
                PermissionCatalog.catalogLocalChangeTaxProfile,
                PermissionCatalog.catalogLocalDisableLocalCopy,
                PermissionCatalog.catalogLocalRequestNewItem,
                PermissionCatalog.catalogPriceHistoryView,
                PermissionCatalog.catalogIdentifiersScan,
                PermissionCatalog.customersView,
                PermissionCatalog.customersCreate,
                PermissionCatalog.customersUpdate,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionViewHistory,
                PermissionCatalog.cashSessionOpen,
                PermissionCatalog.cashSessionClose,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadPDF,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.documentsResendEmail,
                PermissionCatalog.documentsRetryAuthorization,
                PermissionCatalog.documentsViewTimeline,
                PermissionCatalog.documentsViewSriErrors,
                PermissionCatalog.documentsElectronicInvoiceView,
                PermissionCatalog.documentsElectronicInvoiceList,
                PermissionCatalog.documentsElectronicInvoiceDownloadXML,
                PermissionCatalog.documentsElectronicInvoiceDownloadRIDE,
                PermissionCatalog.documentsElectronicInvoiceEmail,
                PermissionCatalog.documentsElectronicInvoiceViewErrors,
                PermissionCatalog.documentsElectronicInvoiceViewAudit,
                PermissionCatalog.taxSettingsView,
                PermissionCatalog.taxSettingsUpdateOrganizationRegime,
                PermissionCatalog.taxProfilesAssignToItem,
                PermissionCatalog.taxProfilesView,
                PermissionCatalog.sriSettingsView,
                PermissionCatalog.sriReadinessRun,
                PermissionCatalog.sriHomologationRunsView,
                PermissionCatalog.electronicSignatureView,
                PermissionCatalog.electronicSignatureValidate,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView,
                PermissionCatalog.reportsCashView,
                PermissionCatalog.reportsTaxView,
                PermissionCatalog.reportsDocumentsView,
                PermissionCatalog.auditView,
                PermissionCatalog.supportDiagnosticsView
            ]
        case .operationsAdmin:
            return [
                PermissionCatalog.organizationView,
                PermissionCatalog.modulesView,
                PermissionCatalog.activitiesView,
                PermissionCatalog.branchesView,
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.catalogLocalCopyFromMaster,
                PermissionCatalog.catalogLocalUpdateLocalCopy,
                PermissionCatalog.catalogLocalChangePrice,
                PermissionCatalog.catalogLocalDisableLocalCopy,
                PermissionCatalog.catalogLocalRequestNewItem,
                PermissionCatalog.catalogPriceHistoryView,
                PermissionCatalog.customersView,
                PermissionCatalog.customersCreate,
                PermissionCatalog.customersUpdate,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionViewHistory,
                PermissionCatalog.cashSessionOpen,
                PermissionCatalog.cashSessionClose,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadPDF,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.documentsResendEmail,
                PermissionCatalog.documentsViewTimeline,
                PermissionCatalog.documentsViewSriErrors,
                PermissionCatalog.taxSettingsView,
                PermissionCatalog.taxProfilesView,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView,
                PermissionCatalog.reportsCashView,
                PermissionCatalog.reportsDocumentsView
            ]
        case .supervisor:
            return [
                PermissionCatalog.activitiesView,
                PermissionCatalog.branchesView,
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.customersView,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionViewHistory,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadPDF,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.documentsViewTimeline,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView,
                PermissionCatalog.reportsCashView,
                PermissionCatalog.reportsDocumentsView
            ]
        case .cashier:
            return [
                PermissionCatalog.customersView,
                PermissionCatalog.customersCreate,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionOpen,
                PermissionCatalog.cashSessionClose,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView,
                PermissionCatalog.reportsCashView
            ]
        case .seller:
            return [
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.customersView,
                PermissionCatalog.customersCreate,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.documentsView,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView
            ]
        case .readOnly:
            return [
                PermissionCatalog.organizationView,
                PermissionCatalog.modulesView,
                PermissionCatalog.activitiesView,
                PermissionCatalog.branchesView,
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.customersView,
                PermissionCatalog.salesView,
                PermissionCatalog.paymentsView,
                PermissionCatalog.receivablesView,
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionViewHistory,
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsDownloadPDF,
                PermissionCatalog.documentsDownloadRide,
                PermissionCatalog.documentsDownloadXML,
                PermissionCatalog.reportsDashboardView,
                PermissionCatalog.reportsSalesView,
                PermissionCatalog.reportsCashView,
                PermissionCatalog.reportsDocumentsView
            ]
        }
    }
}

struct BusinessRoleTemplatePreview: Identifiable, Equatable, Sendable {
    let template: BusinessRoleTemplate
    let availablePermissionKeys: Set<String>

    var id: String { template.id }
    var title: String { template.title }
    var code: String { template.code }
    var description: String { template.description }
    var selectedPermissionKeys: Set<String> { template.permissionKeys.intersection(availablePermissionKeys) }
    var missingPermissionKeys: Set<String> { template.permissionKeys.subtracting(availablePermissionKeys) }
    var canApply: Bool { !selectedPermissionKeys.isEmpty }
    var summary: String {
        if missingPermissionKeys.isEmpty {
            return "\(selectedPermissionKeys.count) permisos disponibles"
        }
        return "\(selectedPermissionKeys.count) disponibles • \(missingPermissionKeys.count) no existen en este backend"
    }
}

extension BusinessRoleTemplate {
    func preview(availablePermissions: [AdminAccessPermission]) -> BusinessRoleTemplatePreview {
        BusinessRoleTemplatePreview(template: self, availablePermissionKeys: Set(availablePermissions.map(\.code)))
    }

    static func previews(availablePermissions: [AdminAccessPermission]) -> [BusinessRoleTemplatePreview] {
        allCases.map { $0.preview(availablePermissions: availablePermissions) }
    }
}
