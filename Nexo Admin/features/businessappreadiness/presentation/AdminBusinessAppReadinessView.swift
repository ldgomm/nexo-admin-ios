//
//  AdminBusinessAppReadinessView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminBusinessAppReadinessView: View {
    @StateObject var viewModel: AdminBusinessAppReadinessViewModel

    var body: some View {
        List { content }
            .navigationTitle("Business App readiness")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await viewModel.refresh() } } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Evaluando readiness…") }

        case .empty(let message):
            Section { EmptyStateView(systemImage: "iphone.gen2.badge.play", title: "Sin readiness", message: message) }

        case .failed(let message):
            Section {
                ErrorStateView(
                    title: "No se pudo evaluar",
                    message: message,
                    retry: { Task { await viewModel.refresh() } }
                )
            }

        case .loaded(let report):
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(report.summaryTitle, systemImage: report.readyForBusinessApp ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.title3.bold())
                        .foregroundStyle(report.readyForBusinessApp ? .green : .red)
                    Text(report.summaryMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    LabeledContent("Organización", value: report.organizationName)
                    LabeledContent("Checks listos", value: "\(report.readyCount)/\(report.totalChecks)")
                    LabeledContent("Advertencias", value: "\(report.warningCount)")
                    LabeledContent("Bloqueantes", value: "\(report.blockedRequiredCount)")
                }
                .padding(.vertical, 6)
            }

            ForEach(report.sections) { section in
                Section(section.title) {
                    ForEach(section.checks) { check in
                        AdminBusinessAppReadinessRow(check: check)
                    }
                }
            }
        }
    }
}

private struct AdminBusinessAppReadinessRow: View {
    let check: AdminBusinessAppReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: check.status.systemImage)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(check.title)
                        .font(.subheadline.weight(.semibold))
                    if check.required {
                        Text("Obligatorio")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                }
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let actionTitle = check.actionTitle {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch check.status {
        case .ready: return .green
        case .warning: return .orange
        case .blocked: return .red
        case .notApplicable: return .secondary
        case .unknown: return .secondary
        }
    }
}
