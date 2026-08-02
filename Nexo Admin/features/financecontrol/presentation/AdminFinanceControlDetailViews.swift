//
//  AdminFinanceControlDetailViews.swift
//  Nexo Admin
//
//  Created by José Ruiz on 29/7/26.
//

import SwiftUI

struct AdminFinanceOrganisationLedgerView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List {
            Section("Alcance") {
                LabeledContent(
                    "Organización",
                    value: snapshot.scope.organizationName
                )
                LabeledContent(
                    "Entidad legal",
                    value: snapshot.scope.legalEntityName
                )
                LabeledContent("Ledger", value: snapshot.scope.ledgerName)
                LabeledContent(
                    "Moneda funcional",
                    value: snapshot.scope.functionalCurrencyCode
                )
                LabeledContent(
                    "Locale",
                    value: snapshot.scope.localeIdentifier
                )
            }

            Section("Política") {
                LabeledContent(
                    "Versión",
                    value: snapshot.configuration.ledgerPolicyVersion
                )
                LabeledContent(
                    "Plan",
                    value: snapshot.configuration.chartVersion
                )
                LabeledContent(
                    "Año fiscal",
                    value: snapshot.configuration.fiscalYearRule
                )
                LabeledContent(
                    "Estado del periodo",
                    value: snapshot.configuration.periodStatus
                )
            }

            Section {
                AdminFinanceControlNotice(
                    title: "Solo lectura",
                    message: "La identidad y la política provienen del backend y no se recalculan en la app.",
                    systemImage: "server.rack",
                    tint: .blue
                )
            }
        }
        .navigationTitle("Entidad y ledger")
    }
}

struct AdminFinanceDimensionsView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List {
            ForEach(snapshot.dimensions) { dimension in
                Section(dimension.displayName) {
                    LabeledContent("Tipo", value: dimension.kind.rawValue)
                    LabeledContent("Estado", value: dimension.status)
                    LabeledContent(
                        "Activos",
                        value: String(dimension.activeCount)
                    )
                    LabeledContent(
                        "Bloqueos",
                        value: String(dimension.blockingIssueCount)
                    )
                    evidenceIds(dimension.evidenceIds)
                }
            }
        }
        .navigationTitle("Plan y dimensiones")
    }

    @ViewBuilder
    private func evidenceIds(_ values: [String]) -> some View {
        if values.isEmpty {
            LabeledContent("Evidencia", value: "Sin referencia")
        } else {
            ForEach(values, id: \.self) { value in
                LabeledContent("Evidencia", value: value)
            }
        }
    }
}

struct AdminFinancePeriodsView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List(snapshot.periods) { period in
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(period.label)
                        .font(.headline)
                    Spacer()
                    AdminFinanceControlStatusBadge(title: period.status)
                }

                LabeledContent("Lock", value: period.lockVersion)
                LabeledContent(
                    "Pendientes",
                    value: String(period.unresolvedCount)
                )
                Text("\(period.evidenceIds.count) referencias de evidencia")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Periodos")
    }
}

struct AdminFinanceImportBatchesView: View {
    let snapshot: AdminFinanceControlSnapshot
    let viewModel: AdminFinanceControlViewModel

    @State private var reviewReason = ""

    var body: some View {
        List {
            Section("Motivo de revisión") {
                TextField(
                    "Motivo obligatorio",
                    text: $reviewReason,
                    axis: .vertical
                )
                Text("El backend conserva actor, motivo y evidencia.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(snapshot.importBatches) { batch in
                Section(batch.fileDisplayName) {
                    LabeledContent("Estado", value: batch.status)
                    LabeledContent(
                        "Aceptadas",
                        value: String(batch.acceptedRows)
                    )
                    LabeledContent(
                        "Rechazadas",
                        value: String(batch.rejectedRows)
                    )
                    LabeledContent(
                        "Errores",
                        value: String(batch.errorCount)
                    )
                    LabeledContent(
                        "Checksum",
                        value: batch.checksumPrefix
                    )

                    Button {
                        Task {
                            await viewModel.reviewImportBatch(
                                id: batch.id,
                                reason: reviewReason
                            )
                        }
                    } label: {
                        Label(
                            "Registrar revisión",
                            systemImage: "checkmark.bubble"
                        )
                    }
                    .disabled(
                        !viewModel.allows(.reviewImportBatch) ||
                        reviewReason.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        viewModel.activeCommand != nil
                    )
                }
            }
        }
        .navigationTitle("Importaciones")
    }
}

struct AdminFinanceCoverageView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List {
            Section("Ejecución") {
                LabeledContent(
                    "Replay",
                    value: snapshot.coverage.replayStatus
                )
                LabeledContent(
                    "Backfill",
                    value: snapshot.coverage.backfillStatus
                )
                LabeledContent(
                    "Cobertura",
                    value: snapshot.coverage.coverageStatus
                )
            }

            Section("Readiness") {
                LabeledContent(
                    "Rubros requeridos",
                    value: String(snapshot.coverage.requiredRubrics)
                )
                LabeledContent(
                    "Rubros conciliados",
                    value: String(snapshot.coverage.reconciledRubrics)
                )
                LabeledContent(
                    "Bloqueos",
                    value: String(snapshot.coverage.unresolvedBlockingCount)
                )

                if let explanation =
                    snapshot.coverage.exactDifferenceExplanation {
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Evidencia") {
                ForEach(snapshot.coverage.evidenceIds, id: \.self) { id in
                    Text(id)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Replay y cobertura")
    }
}

struct AdminFinanceReconciliationExceptionsView: View {
    let snapshot: AdminFinanceControlSnapshot
    let viewModel: AdminFinanceControlViewModel

    @State private var reviewReason = ""

    var body: some View {
        List {
            Section("Motivo de revisión") {
                TextField(
                    "Motivo obligatorio",
                    text: $reviewReason,
                    axis: .vertical
                )
            }

            ForEach(snapshot.reconciliationExceptions) { item in
                Section(item.title) {
                    LabeledContent(
                        "Clasificación",
                        value: item.classification
                    )
                    LabeledContent("Estado", value: item.status)
                    LabeledContent(
                        "Bloqueante",
                        value: item.blocking ? "Sí" : "No"
                    )
                    Text(item.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await viewModel.reviewReconciliationException(
                                id: item.id,
                                reason: reviewReason
                            )
                        }
                    } label: {
                        Label(
                            "Registrar revisión",
                            systemImage: "checkmark.bubble"
                        )
                    }
                    .disabled(
                        !viewModel.allows(
                            .reviewReconciliationException
                        ) ||
                        reviewReason.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        viewModel.activeCommand != nil
                    )
                }
            }
        }
        .navigationTitle("Excepciones")
    }
}

struct AdminFinanceCutoverApprovalView: View {
    let snapshot: AdminFinanceControlSnapshot
    let viewModel: AdminFinanceControlViewModel

    @State private var approvalReason = ""

    var body: some View {
        List {
            Section("Estado autoritativo") {
                LabeledContent("Estado", value: snapshot.cutover.status)
                LabeledContent(
                    "Fecha propuesta",
                    value: snapshot.cutover.proposedDate ?? "No definida"
                )
                LabeledContent(
                    "Bloqueos",
                    value: String(snapshot.cutover.unresolvedBlockingCount)
                )
                LabeledContent(
                    "Solapamientos",
                    value: String(snapshot.cutover.overlapCount)
                )
                LabeledContent(
                    "Brechas",
                    value: String(snapshot.cutover.gapCount)
                )
            }

            Section("Aprobación") {
                TextField(
                    "Motivo obligatorio",
                    text: $approvalReason,
                    axis: .vertical
                )

                Button {
                    Task {
                        await viewModel.approveCutover(
                            reason: approvalReason
                        )
                    }
                } label: {
                    Label(
                        "Aprobar cutover",
                        systemImage: "checkmark.seal"
                    )
                }
                .disabled(
                    !canAttemptApproval ||
                    approvalReason.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty ||
                    viewModel.activeCommand != nil
                )

                Text("La aprobación exige permiso, capacidad del backend, cero brechas/solapamientos, cero bloqueos, evidencia y motivo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Cutover")
    }

    private var canAttemptApproval: Bool {
        viewModel.allows(.approveCutover) &&
        snapshot.cutover.backendEligibleForApproval &&
        snapshot.cutover.unresolvedBlockingCount == 0 &&
        snapshot.coverage.unresolvedBlockingCount == 0 &&
        snapshot.cutover.overlapCount == 0 &&
        snapshot.cutover.gapCount == 0 &&
        !snapshot.cutover.approvalEvidenceIds.isEmpty &&
        !snapshot.coverage.evidenceIds.isEmpty
    }
}

struct AdminFinanceJurisdictionCapabilitiesView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List {
            Section("Pack") {
                LabeledContent(
                    "Jurisdicción",
                    value: snapshot.jurisdiction.jurisdictionCode
                )
                LabeledContent(
                    "Identificador",
                    value: snapshot.jurisdiction.packIdentifier
                )
                LabeledContent(
                    "Versión",
                    value: snapshot.jurisdiction.packVersion
                )
            }

            Section("Capacidades verificadas") {
                capabilityRows(
                    snapshot.jurisdiction.verifiedCapabilityCodes,
                    emptyMessage: "Sin capacidades verificadas"
                )
            }

            Section("Capacidades no verificadas") {
                capabilityRows(
                    snapshot.jurisdiction.unverifiedCapabilityCodes,
                    emptyMessage: "Sin capacidades pendientes"
                )
            }

            Section("Declaración") {
                Text(
                    snapshot.jurisdiction.complianceStatement ??
                        "No existe una afirmación de cumplimiento."
                )
                .font(.subheadline)

                Text("La app muestra únicamente afirmaciones respaldadas por capacidad verificada y evidencia.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Jurisdicción")
    }

    @ViewBuilder
    private func capabilityRows(
        _ values: [String],
        emptyMessage: String
    ) -> some View {
        if values.isEmpty {
            Text(emptyMessage)
                .foregroundStyle(.secondary)
        } else {
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
    }
}

struct AdminFinanceAuditEvidenceView: View {
    let snapshot: AdminFinanceControlSnapshot

    var body: some View {
        List(snapshot.evidence) { item in
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(item.displayName)
                        .font(.headline)
                    Spacer()
                    AdminFinanceControlStatusBadge(
                        title: item.kind,
                        tint: .blue
                    )
                }

                Text(item.occurredAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let actor = item.actorDisplayName {
                    LabeledContent("Actor", value: actor)
                }
                if let reference = item.maskedExternalReference {
                    LabeledContent("Referencia", value: reference)
                }

                Text(item.id)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Auditoría y evidencia")
    }
}
