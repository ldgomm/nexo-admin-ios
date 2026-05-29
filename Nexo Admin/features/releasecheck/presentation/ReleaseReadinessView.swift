//
//  ReleaseReadinessView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct ReleaseReadinessView: View {
    @StateObject var viewModel: ReleaseReadinessViewModel

    var body: some View {
        List {
            if let report = viewModel.report {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(report.summaryTitle, systemImage: report.isReadyForInternalTestFlight ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.title3.bold())
                            .foregroundStyle(report.isReadyForInternalTestFlight ? .green : .red)

                        Text(report.summaryMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LabeledContent("Build", value: report.buildInfo.displayVersion)
                        LabeledContent("Configuración", value: report.buildInfo.configuration.rawValue)
                        LabeledContent("API", value: report.buildInfo.apiBaseURL)
                    }
                    .padding(.vertical, 6)
                }

                ForEach(report.sections) { section in
                    Section(section.title) {
                        ForEach(section.checks) { check in
                            ReleaseReadinessCheckRow(check: check)
                        }
                    }
                }
            } else {
                Section {
                    ProgressView("Preparando checklist…")
                }
            }
        }
        .navigationTitle("Cierre técnico")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            viewModel.load()
        }
    }
}

private struct ReleaseReadinessCheckRow: View {
    let check: ReleaseReadinessCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: check.status.systemImage)
                .font(.title3)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
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

                Text(check.status.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch check.status {
        case .passed: return .green
        case .warning: return .orange
        case .failed: return .red
        case .manual: return .blue
        }
    }
}
