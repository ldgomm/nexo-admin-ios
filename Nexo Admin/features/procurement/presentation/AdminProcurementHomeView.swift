//
//  AdminProcurementHomeView.swift
//  Nexo Admin
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
                                message: "Solicita suppliers.view, purchase_orders.view, purchase_receipts.view o el conjunto completo de permisos de readiness.",
                                tone: .warning
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Compras")
    }

    private var canAccessAnySurface: Bool {
        AdminSupplierAccess.canView(permissions)
            || AdminPurchaseOrderAccess.canView(permissions)
            || AdminPurchaseReceiptAccess.canView(permissions)
            || AdminProcurementReadinessAccess.allows(permissions)
    }
}
