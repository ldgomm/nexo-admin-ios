//
//  AdminAccessComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminAccessStatusBadge: View {
    let text: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.quaternary)
        .clipShape(Capsule())
    }
}

struct AdminAccessWarningCallout: View {
    let messages: [String]

    var body: some View {
        if !messages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(messages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct AdminAccessSecretCard: View {
    let title: String
    let secret: String
    let message: String

    var body: some View {
        HCard {
            Label(title, systemImage: "key.fill")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(secret)
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct AdminAccessReasonField: View {
    let title: String
    @Binding var reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Motivo obligatorio", text: $reason, axis: .vertical)
                .lineLimit(2...4)
                .padding(12)
                .background(.quaternary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct BusinessRoleTemplatePicker: View {
    let previews: [BusinessRoleTemplatePreview]
    let selectedTemplate: BusinessRoleTemplate?
    let apply: (BusinessRoleTemplate) -> Void
    let clear: () -> Void

    var body: some View {
        Section("Plantillas Business 17G") {
            if previews.isEmpty {
                Text("Carga permisos para aplicar plantillas.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(previews) { preview in
                    Button {
                        apply(preview.template)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedTemplate == preview.template ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedTemplate == preview.template ? Color.accentColor : .secondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preview.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(preview.code)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(preview.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!preview.canApply)
                }
                if selectedTemplate != nil {
                    Button("Limpiar plantilla", action: clear)
                }
            }
        }
    }
}

struct RoleSelectionList: View {
    let roles: [AdminAccessRole]
    @Binding var selectedRoleIds: Set<String>

    private var assignableRoles: [AdminAccessRole] {
        roles.assignableFromAdmin
    }

    var body: some View {
        if assignableRoles.isEmpty {
            EmptyStateView(
                systemImage: "person.2.slash",
                title: "Sin roles asignables",
                message: "Primero carga o crea un rol activo de organización. Los roles inactivos o protegidos no se asignan desde este selector."
            )
        } else {
            ForEach(assignableRoles) { role in
                Button {
                    toggle(role.id)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedRoleIds.contains(role.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedRoleIds.contains(role.id) ? Color.accentColor : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(role.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(role.code)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text(role.permissionCountLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedRoleIds.contains(id) {
            selectedRoleIds.remove(id)
        } else {
            selectedRoleIds.insert(id)
        }
    }
}

struct PermissionSelectionList: View {
    let permissions: [AdminAccessPermission]
    @Binding var selectedPermissionKeys: Set<String>

    var body: some View {
        if permissions.isEmpty {
            EmptyStateView(
                systemImage: "checklist.unchecked",
                title: "Sin permisos visibles",
                message: "Ajusta el filtro o revisa que el backend publique permisos activos."
            )
        } else {
            let groups = Dictionary(grouping: permissions.sortedByCategoryAndName, by: \.categoryLabel)
            ForEach(groups.keys.sorted(), id: \.self) { category in
                Section(category) {
                    ForEach(groups[category].orEmpty) { permission in
                        Button {
                            toggle(permission.code)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedPermissionKeys.contains(permission.code) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(selectedPermissionKeys.contains(permission.code) ? Color.accentColor : .secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(permission.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(permission.code)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                    Text(permission.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    HStack(spacing: 6) {
                                        if permission.isHighRisk { AdminAccessStatusBadge(text: "Alto riesgo") }
                                        if permission.requiresReason { AdminAccessStatusBadge(text: "Motivo") }
                                        if permission.requiresAudit { AdminAccessStatusBadge(text: "Auditado") }
                                        if permission.requiresStepUp { AdminAccessStatusBadge(text: "Crítico") }
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func toggle(_ key: String) {
        if selectedPermissionKeys.contains(key) {
            selectedPermissionKeys.remove(key)
        } else {
            selectedPermissionKeys.insert(key)
        }
    }
}

extension Optional where Wrapped == Array<AdminAccessPermission> {
    var orEmpty: [AdminAccessPermission] { self ?? [] }
}

extension Array where Element == AdminAccessRole {
    var sortedByName: [AdminAccessRole] {
        sorted { lhs, rhs in lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
    }
}

extension Array where Element == AdminAccessPermission {
    var sortedByCategoryAndName: [AdminAccessPermission] {
        sorted {
            if $0.category == $1.category {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
        }
    }
}
