//
//  AdminProcurementHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//
//  27R.N.3 — Extensible Admin procurement control hub.
//

import SwiftUI

struct AdminProcurementHomeView: View {
    let foundationRepository: any AdminFoundationRepository
    let procurementRepository: any AdminProcurementRepository
    let permissions: Set<String>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                NexoAdminUXHeroCard(
                    eyebrow: "Control purchase-to-pay",
                    title: "Compras y cuentas por pagar",
                    subtitle: "Configuración y supervisión administrativa sobre contratos canónicos del backend.",
                    systemImage: "shippingbox.and.arrow.forward.fill",
                    badgeTitle: "Operativo",
                    badgeSystemImage: "checkmark.shield.fill"
                )

                NexoAdminUXInlineMessage(
                    title: "Frontera financiera",
                    message: "Admin gestiona proveedores y revisa hechos operativos. No recalcula saldos ni presenta esta información como contabilidad oficial.",
                    tone: .info
                )

                NexoAdminUXCard {
                    NexoAdminUXSectionHeader(
                        "Configuración y salud",
                        subtitle: "Cada superficie respeta los permisos efectivos y la organización activa.",
                        systemImage: "slider.horizontal.3"
                    )

                    VStack(spacing: 10) {
                        if AdminSupplierAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Proveedores",
                                subtitle: "Buscar, crear, editar y cambiar estado con versión, motivo y auditoría.",
                                systemImage: "building.2.fill"
                            ) {
                                AdminSupplierListView(
                                    viewModel: AdminSupplierViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminPurchaseOrderAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Órdenes de compra",
                                subtitle: "Supervisar estado, recepción, costos autorizados y evidencia del ciclo de vida.",
                                systemImage: "doc.text.magnifyingglass"
                            ) {
                                AdminPurchaseOrderListView(
                                    viewModel: AdminPurchaseOrderViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminPurchaseReceiptAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Recepciones e inventario",
                                subtitle: "Revisar cantidades recibidas y su efecto canónico, sin mutaciones ni cálculos locales.",
                                systemImage: "shippingbox.and.arrow.backward.fill"
                            ) {
                                AdminPurchaseReceiptListView(
                                    viewModel: AdminPurchaseReceiptViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminSupplierDocumentAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Documentos de proveedor",
                                subtitle: "Revisar facturas y gastos, importes, impuestos, vínculos, evidencia y cuenta por pagar.",
                                systemImage: "doc.text.fill"
                            ) {
                                AdminSupplierDocumentListView(
                                    viewModel: AdminSupplierDocumentViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminPayableAccess.canEnter(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Cuentas por pagar",
                                subtitle: "Supervisar saldos, vencimientos, ageing y fuentes canónicas sin recalcular ni modificar.",
                                systemImage: "calendar.badge.exclamationmark"
                            ) {
                                AdminPayableListView(
                                    viewModel: AdminPayableViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }


                        if AdminSupplierPaymentAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Pagos a proveedores",
                                subtitle: "Revisar aplicaciones, evidencia y anular con permiso; el backend restaura saldos sin borrar historial.",
                                systemImage: "banknote.fill"
                            ) {
                                AdminSupplierPaymentListView(
                                    viewModel: AdminSupplierPaymentViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }


                        if AdminSupplierStatementAccess.canView(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Estado de cuenta proveedor",
                                subtitle: "Consultar cargos, pagos, reversos, saldos y CSV canónico sin cálculos locales.",
                                systemImage: "list.bullet.rectangle.portrait.fill"
                            ) {
                                AdminSupplierStatementView(
                                    viewModel: AdminSupplierStatementViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminProcurementExportAccess.canViewCatalog(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Exportaciones operativas",
                                subtitle: "Descargar los nueve reportes reconciliados publicados por el catálogo backend.",
                                systemImage: "square.and.arrow.down.on.square.fill"
                            ) {
                                AdminProcurementExportsView(
                                    viewModel: AdminProcurementExportsViewModel(
                                        repository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if AdminProcurementReadinessAccess.allows(permissions) {
                            NexoAdminUXNavigationTile(
                                title: "Readiness y reconciliación",
                                subtitle: "Módulos, reportes, CxP y hechos financieros reconciliados por backend.",
                                systemImage: "checklist.checked"
                            ) {
                                AdminProcurementReadinessView(
                                    viewModel: AdminProcurementReadinessViewModel(
                                        foundationRepository: foundationRepository,
                                        procurementRepository: procurementRepository,
                                        permissions: permissions
                                    )
                                )
                            }
                        }

                        if !canAccessAnySurface {
                            NexoAdminUXInlineMessage(
                                title: "Sin permisos de compras",
                                message: "Solicita permisos de proveedores, órdenes, recepciones, documentos, cuentas por pagar, pagos, estados de cuenta, reportes o readiness.",
                                tone: .warning
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Compras y proveedores")
    }

    private var canAccessAnySurface: Bool {
        AdminSupplierAccess.canView(permissions)
            || AdminPurchaseOrderAccess.canView(permissions)
            || AdminPurchaseReceiptAccess.canView(permissions)
            || AdminSupplierDocumentAccess.canView(permissions)
            || AdminPayableAccess.canEnter(permissions)
            || AdminSupplierPaymentAccess.canView(permissions)
            || AdminSupplierStatementAccess.canView(permissions)
            || AdminProcurementExportAccess.canViewCatalog(permissions)
            || AdminProcurementReadinessAccess.allows(permissions)
    }
}
