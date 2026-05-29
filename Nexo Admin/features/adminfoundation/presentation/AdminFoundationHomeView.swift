//
//  AdminFoundationHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminFoundationHomeView: View {
    @StateObject var viewModel: AdminFoundationViewModel
    @State private var moduleForAction: AdminResolvedModule?

    var body: some View {
        List {
            content
        }
        .navigationTitle("Foundation v2.4")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await viewModel.refresh() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Listo", isPresented: successBinding) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .sheet(item: $moduleForAction) { module in
            NavigationStack {
                AdminModuleToggleView(
                    module: module,
                    reason: $viewModel.actionDraft.reason,
                    enable: viewModel.actionDraft.enable,
                    isMutating: viewModel.isMutating,
                    onCancel: { moduleForAction = nil },
                    onConfirm: {
                        await viewModel.runToggle()
                        if viewModel.errorMessage == nil {
                            moduleForAction = nil
                        }
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section {
                ProgressView("Cargando foundation v2.4…")
            }

        case .empty(let message):
            Section {
                EmptyStateView(systemImage: "puzzlepiece.extension", title: "Sin datos", message: message)
            }

        case .failed(let message):
            Section {
                ErrorStateView(title: "No se pudo cargar foundation", message: message, retry: { Task { await viewModel.refresh() } })
            }

        case .loaded(let snapshot):
            Section {
                BusinessContextSummaryCard(snapshot: snapshot)
            }

            if !snapshot.blockedModules.isEmpty {
                Section("Bloqueos") {
                    ForEach(snapshot.blockedModules) { module in
                        ModuleProblemRow(module: module, readiness: snapshot.readinessByCode[module.code])
                    }
                }
            }

            Section("Módulos activos") {
                if snapshot.activeModules.isEmpty {
                    Text("No hay módulos activos adicionales.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.activeModules) { module in
                        ModuleRow(
                            module: module,
                            readiness: snapshot.readinessByCode[module.code],
                            canManage: viewModel.canManageModules,
                            action: { presentToggle(module) }
                        )
                    }
                }
            }

            Section("Módulos disponibles") {
                if snapshot.inactiveModules.isEmpty {
                    Text("No hay módulos inactivos.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.inactiveModules) { module in
                        ModuleRow(
                            module: module,
                            readiness: snapshot.readinessByCode[module.code],
                            canManage: viewModel.canManageModules,
                            action: { presentToggle(module) }
                        )
                    }
                }
            }
        }
    }

    private func presentToggle(_ module: AdminResolvedModule) {
        viewModel.prepareToggle(module: module)
        moduleForAction = module
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }

    private var successBinding: Binding<Bool> {
        Binding(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })
    }
}

private struct BusinessContextSummaryCard: View {
    let snapshot: AdminFoundationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.context.displayName)
                        .font(.headline)
                    Text(snapshot.operationalSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminFoundationBadge(
                    text: snapshot.context.realtime.enabled ? "Realtime ON" : "Realtime preparado",
                    systemImage: snapshot.context.realtime.enabled ? "bolt.fill" : "bolt.slash"
                )
            }

            Divider()

            Label("Sucursal activa: \(snapshot.context.activeBranch?.name ?? "No definida")", systemImage: "mappin.and.ellipse")
            Label("Catalog revision: \(snapshot.context.catalogRevision)", systemImage: "tag")
            Label("Tax revision: \(snapshot.context.taxConfigurationRevision)", systemImage: "percent")
            Label("SSE: \(snapshot.context.realtime.sseUrl)", systemImage: "antenna.radiowaves.left.and.right")
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

private struct ModuleRow: View {
    let module: AdminResolvedModule
    let readiness: AdminModuleReadinessItem?
    let canManage: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(module.name)
                        .font(.headline)
                    Text(module.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AdminFoundationBadge(
                    text: module.activeTitle,
                    systemImage: module.active ? "checkmark.circle.fill" : "circle"
                )
            }

            Text("\(module.categoryTitle) · \(module.source.nexoReadableKey) · \(module.statusTitle)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let readiness, readiness.hasProblems {
                ModuleReadinessProblemsView(readiness: readiness)
            }

            if !module.dependencies.isEmpty {
                Text("Depende de: \(module.dependencies.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if canManage {
                Button(module.active ? "Desactivar módulo" : "Activar módulo", action: action)
                    .buttonStyle(.bordered)
                    .disabled(!module.active && !module.canBeEnabled)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ModuleProblemRow: View {
    let module: AdminResolvedModule
    let readiness: AdminModuleReadinessItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(module.name)
                .font(.headline)
            Text(module.code)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            ForEach(module.blockedReasons, id: \.self) { reason in
                Label(reason, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let readiness {
                ModuleReadinessProblemsView(readiness: readiness)
            }
        }
    }
}

private struct ModuleReadinessProblemsView: View {
    let readiness: AdminModuleReadinessItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(readiness.missingDependencies, id: \.self) { value in
                Label("Falta dependencia: \(value)", systemImage: "link.badge.plus")
            }
            ForEach(readiness.blockers, id: \.self) { value in
                Label(value, systemImage: "xmark.octagon")
            }
            ForEach(readiness.warnings, id: \.self) { value in
                Label(value, systemImage: "exclamationmark.triangle")
            }
        }
        .font(.caption)
        .foregroundStyle(.orange)
    }
}

private struct AdminFoundationBadge: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary)
        .clipShape(Capsule())
    }
}

private struct AdminModuleToggleView: View {
    let module: AdminResolvedModule
    @Binding var reason: String
    let enable: Bool
    let isMutating: Bool
    let onCancel: () -> Void
    let onConfirm: () async -> Void

    var body: some View {
        Form {
            Section("Módulo") {
                LabeledContent("Nombre", value: module.name)
                LabeledContent("Código", value: module.code)
                LabeledContent("Acción", value: enable ? "Activar" : "Desactivar")
            }

            if !module.blockedReasons.isEmpty && enable {
                Section("Bloqueos") {
                    ForEach(module.blockedReasons, id: \.self) { reason in
                        Text(reason)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Auditoría") {
                TextField("Motivo obligatorio", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(enable ? "Activar módulo" : "Desactivar módulo")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(enable ? "Activar" : "Desactivar", role: enable ? nil : .destructive) {
                    Task { await onConfirm() }
                }
                .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isMutating || (enable && !module.canBeEnabled))
            }
        }
    }
}
