//
//  AdminAccessComponents.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
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

struct RoleSelectionList: View {
    let roles: [AdminAccessRole]
    @Binding var selectedRoleIds: Set<String>

    var body: some View {
        if roles.isEmpty {
            EmptyStateView(
                systemImage: "person.2.slash",
                title: "Sin roles disponibles",
                message: "Primero carga roles o crea un rol activo para poder asignarlo."
            )
        } else {
            ForEach(roles.sortedByName) { role in
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
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !role.isActive {
                                Text("Rol inactivo")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                        }
                        Spacer()
                        Text("\(role.permissionKeys.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
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
                                if permission.requiresReason || permission.requiresAudit || permission.requiresStepUp {
                                    HStack(spacing: 6) {
                                        if permission.requiresReason { AdminAccessStatusBadge(text: "Motivo") }
                                        if permission.requiresAudit { AdminAccessStatusBadge(text: "Auditado") }
                                        if permission.requiresStepUp { AdminAccessStatusBadge(text: "Crítico") }
                                    }
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
