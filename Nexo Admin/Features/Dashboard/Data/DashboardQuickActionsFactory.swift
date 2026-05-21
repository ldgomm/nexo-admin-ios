//
//  DashboardQuickActionsFactory.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum DashboardQuickActionsFactory {
    static let actions: [DashboardQuickAction] = [
        DashboardQuickAction(
            id: "users",
            title: "Usuarios",
            subtitle: "Equipo, bloqueo y reset",
            systemImage: "person.2.fill",
            requiredPermissions: [PermissionCatalog.credentialsUsersView, PermissionCatalog.credentialsUsersCreate],
            destination: .users
        ),
        DashboardQuickAction(
            id: "business",
            title: "Negocio",
            subtitle: "Datos, actividades y sucursales",
            systemImage: "building.2.fill",
            requiredPermissions: [PermissionCatalog.organizationView, PermissionCatalog.activitiesView, PermissionCatalog.branchesView],
            destination: .business
        ),
        DashboardQuickAction(
            id: "catalog",
            title: "Catálogo",
            subtitle: "Productos, servicios y solicitudes",
            systemImage: "square.grid.2x2.fill",
            requiredPermissions: [PermissionCatalog.catalogLocalView, PermissionCatalog.catalogLocalManage],
            destination: .catalog
        ),
        DashboardQuickAction(
            id: "tax",
            title: "Tributario",
            subtitle: "Tax settings y perfiles",
            systemImage: "percent",
            requiredPermissions: [PermissionCatalog.taxSettingsView, PermissionCatalog.taxManage],
            destination: .tax
        ),
        DashboardQuickAction(
            id: "cash",
            title: "Caja",
            subtitle: "Estado y reporte diario",
            systemImage: "banknote.fill",
            requiredPermissions: [PermissionCatalog.reportsCash, PermissionCatalog.cashViewCurrent, PermissionCatalog.cashViewHistory],
            destination: .cash
        ),
        DashboardQuickAction(
            id: "documents",
            title: "Comprobantes",
            subtitle: "RIDE, XML y errores SRI",
            systemImage: "doc.text.fill",
            requiredPermissions: [PermissionCatalog.documentsView, PermissionCatalog.reportsDocuments],
            destination: .documents
        ),
        DashboardQuickAction(
            id: "signature",
            title: "Firma",
            subtitle: "Validez y vencimiento",
            systemImage: "signature",
            requiredPermissions: [PermissionCatalog.signatureViewMetadata, PermissionCatalog.signatureUpload, PermissionCatalog.signatureTest],
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
