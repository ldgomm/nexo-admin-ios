//
//  DashboardQuickActionsFactory.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

enum DashboardQuickActionsFactory {
    static let actions: [DashboardQuickAction] = [
        DashboardQuickAction(
            id: "users",
            title: "Usuarios",
            subtitle: "Equipo, bloqueo y reset",
            systemImage: "person.2.fill",
            requiredPermissions: [
                PermissionCatalog.credentialsUsersView,
                PermissionCatalog.credentialsUsersCreate,
                PermissionCatalog.credentialsUsersInvite
            ],
            destination: .users
        ),
        DashboardQuickAction(
            id: "business",
            title: "Negocio",
            subtitle: "Datos, actividades y sucursales",
            systemImage: "building.2.fill",
            requiredPermissions: [
                PermissionCatalog.organizationView,
                PermissionCatalog.organizationUpdate,
                PermissionCatalog.activitiesView,
                PermissionCatalog.branchesView,
                PermissionCatalog.emissionPointsView
            ],
            destination: .business
        ),
        DashboardQuickAction(
            id: "catalog",
            title: "Catálogo",
            subtitle: "Productos, servicios y solicitudes",
            systemImage: "square.grid.2x2.fill",
            requiredPermissions: [
                PermissionCatalog.catalogLocalView,
                PermissionCatalog.catalogLocalCopyFromMaster,
                PermissionCatalog.catalogLocalUpdateLocalCopy,
                PermissionCatalog.catalogLocalChangePrice,
                PermissionCatalog.catalogLocalRequestNewItem
            ],
            destination: .catalog
        ),
        DashboardQuickAction(
            id: "tax",
            title: "Tributario",
            subtitle: "Configuración y perfiles",
            systemImage: "percent",
            requiredPermissions: [
                PermissionCatalog.taxSettingsView,
                PermissionCatalog.taxSettingsUpdateOrganizationRegime,
                PermissionCatalog.reportsTaxView
            ],
            destination: .tax
        ),
        DashboardQuickAction(
            id: "cash",
            title: "Caja",
            subtitle: "Estado y reporte diario",
            systemImage: "banknote.fill",
            requiredPermissions: [
                PermissionCatalog.cashView,
                PermissionCatalog.cashSessionViewCurrent,
                PermissionCatalog.cashSessionViewHistory,
                PermissionCatalog.reportsCashView,
                PermissionCatalog.reportsDashboardView
            ],
            destination: .cash
        ),
        DashboardQuickAction(
            id: "documents",
            title: "Comprobantes",
            subtitle: "RIDE, XML y errores SRI",
            systemImage: "doc.text.fill",
            requiredPermissions: [
                PermissionCatalog.documentsView,
                PermissionCatalog.documentsElectronicInvoiceView,
                PermissionCatalog.documentsElectronicInvoiceList,
                PermissionCatalog.documentsElectronicInvoiceViewErrors,
                PermissionCatalog.reportsDocumentsView
            ],
            destination: .documents
        ),
        DashboardQuickAction(
            id: "signature",
            title: "Firma",
            subtitle: "Validez y pruebas",
            systemImage: "signature",
            requiredPermissions: [
                PermissionCatalog.signatureViewAudit,
                PermissionCatalog.signatureReplace,
                PermissionCatalog.signatureTest
            ],
            destination: .signature
        ),
        DashboardQuickAction(
            id: "audit",
            title: "Auditoría",
            subtitle: "Eventos críticos",
            systemImage: "clock.arrow.circlepath",
            requiredPermissions: [PermissionCatalog.auditView],
            destination: .audit
        )
    ]
}
