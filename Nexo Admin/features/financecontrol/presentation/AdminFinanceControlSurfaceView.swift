//
//  AdminFinanceControlSurfaceView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import SwiftUI

struct AdminFinanceControlSurfaceView: View {
    @Bindable private var viewModel: AdminFinanceControlViewModel

    init(
        effectivePermissions: Set<String>,
        repository: any AdminFinanceControlRepository
    ) {
        self.viewModel = AdminFinanceControlViewModel(
            effectivePermissions: effectivePermissions,
            repository: repository
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                hero

                if viewModel.isLoading, viewModel.snapshot == nil {
                    loadingCard
                } else if let snapshot = viewModel.snapshot {
                    sourceStatusCard(snapshot)
                    navigationCard(snapshot)
                } else {
                    unavailableCard
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Control financiero")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await viewModel.load() }
        .task { await viewModel.loadIfNeeded() }
        .alert(
            "Control financiero",
            isPresented: Binding(
                get: {
                    viewModel.errorMessage != nil ||
                        viewModel.successMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearMessages()
                    }
                }
            )
        ) {
            Button("Entendido", role: .cancel) {
                viewModel.clearMessages()
            }
        } message: {
            Text(viewModel.errorMessage ?? viewModel.successMessage ?? "")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "chart.line.text.clipboard")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 48, height: 48)
                    .background(
                        Color.indigo.opacity(0.12),
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Supervisión financiera")
                        .font(.title2.weight(.bold))

                    Text("Políticas, periodos, importaciones, cobertura, excepciones, cutover y evidencia.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            AdminFinanceControlNotice(
                title: "Operativo · no contabilizado",
                message: "Esta superficie no crea asientos, no publica estados financieros y no declara cumplimiento de un país sin capacidad verificada.",
                systemImage: "checkmark.shield",
                tint: .orange
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.14),
                    Color(uiColor: .secondarySystemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
    }

    private var loadingCard: some View {
        AdminFinanceControlSectionCard(
            title: "Cargando",
            subtitle: "Consultando la fuente autoritativa.",
            systemImage: "arrow.triangle.2.circlepath"
        ) {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }

    private var unavailableCard: some View {
        AdminFinanceControlSectionCard(
            title: "Datos todavía no disponibles",
            subtitle: "La pantalla falla de forma cerrada y no inventa valores.",
            systemImage: "lock.shield"
        ) {
            AdminFinanceControlNotice(
                title: "Conexión segura pendiente",
                message: viewModel.errorMessage ??
                    "No se recibió una respuesta financiera válida.",
                systemImage: "info.circle",
                tint: .secondary
            )

            Button {
                Task { await viewModel.load() }
            } label: {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func sourceStatusCard(
        _ snapshot: AdminFinanceControlSnapshot
    ) -> some View {
        AdminFinanceControlSectionCard(
            title: "Fuente y alcance",
            subtitle: "Identidad recibida del backend; sin agregación autoritativa local.",
            systemImage: "server.rack"
        ) {
            AdminFinanceControlFactRow(
                title: "Organización",
                value: snapshot.scope.organizationName,
                systemImage: "building.2"
            )
            AdminFinanceControlFactRow(
                title: "Entidad legal",
                value: snapshot.scope.legalEntityName,
                systemImage: "building.columns"
            )
            AdminFinanceControlFactRow(
                title: "Ledger",
                value: snapshot.scope.ledgerName,
                systemImage: "books.vertical"
            )
            AdminFinanceControlFactRow(
                title: "Periodo",
                value: snapshot.scope.periodLabel,
                systemImage: "calendar"
            )
            AdminFinanceControlFactRow(
                title: "Estado",
                value: snapshot.accountingStatus.safeDisplayTitle,
                systemImage: "checkmark.shield",
                tint: .orange
            )
        }
    }

    private func navigationCard(
        _ snapshot: AdminFinanceControlSnapshot
    ) -> some View {
        AdminFinanceControlSectionCard(
            title: "Áreas de supervisión",
            subtitle: "Cada vista conserva permisos, capacidad del backend y evidencia.",
            systemImage: "square.grid.2x2"
        ) {
            VStack(spacing: 10) {
                if viewModel.canView(.organisationAndLedger) {
                    NavigationLink {
                        AdminFinanceOrganisationLedgerView(snapshot: snapshot)
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Entidad, ledger y política",
                            subtitle: snapshot.configuration.ledgerPolicyVersion,
                            systemImage: "building.columns"
                        )
                    }
                }

                if viewModel.canView(.chartCategoryAndCostCentre) {
                    NavigationLink {
                        AdminFinanceDimensionsView(snapshot: snapshot)
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Plan, categorías y centros",
                            subtitle: "\(snapshot.dimensions.count) ámbitos",
                            systemImage: "list.bullet.rectangle"
                        )
                    }
                }

                if viewModel.canView(.periods) {
                    NavigationLink {
                        AdminFinancePeriodsView(snapshot: snapshot)
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Periodos",
                            subtitle: "\(snapshot.periods.count) periodos",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                }

                if viewModel.canView(.importBatches) {
                    NavigationLink {
                        AdminFinanceImportBatchesView(
                            snapshot: snapshot,
                            viewModel: viewModel
                        )
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Lotes de importación",
                            subtitle: "\(snapshot.importBatches.count) lotes",
                            systemImage: "tray.and.arrow.down"
                        )
                    }
                }

                if viewModel.canView(.replayBackfillAndCoverage) {
                    NavigationLink {
                        AdminFinanceCoverageView(snapshot: snapshot)
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Replay, backfill y cobertura",
                            subtitle: snapshot.coverage.coverageStatus,
                            systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                        )
                    }
                }

                if viewModel.canView(.reconciliationExceptions) {
                    NavigationLink {
                        AdminFinanceReconciliationExceptionsView(
                            snapshot: snapshot,
                            viewModel: viewModel
                        )
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Excepciones de conciliación",
                            subtitle: "\(snapshot.reconciliationExceptions.count) excepciones",
                            systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
                        )
                    }
                }

                if viewModel.canView(.cutoverApproval) {
                    NavigationLink {
                        AdminFinanceCutoverApprovalView(
                            snapshot: snapshot,
                            viewModel: viewModel
                        )
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Aprobación de cutover",
                            subtitle: snapshot.cutover.status,
                            systemImage: "checkmark.seal"
                        )
                    }
                }

                if viewModel.canView(.jurisdictionCapabilities) {
                    NavigationLink {
                        AdminFinanceJurisdictionCapabilitiesView(
                            snapshot: snapshot
                        )
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Jurisdicción y capacidades",
                            subtitle: snapshot.jurisdiction.packIdentifier,
                            systemImage: "globe"
                        )
                    }
                }

                if viewModel.canView(.auditAndEvidence) {
                    NavigationLink {
                        AdminFinanceAuditEvidenceView(snapshot: snapshot)
                    } label: {
                        AdminFinanceControlDestinationRow(
                            title: "Auditoría y evidencia",
                            subtitle: "\(snapshot.evidence.count) referencias",
                            systemImage: "doc.text.magnifyingglass"
                        )
                    }
                }
            }
        }
    }
}
