//
//  AdminUserDetailView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminUserDetailView: View {
    @StateObject var viewModel: AdminUserDetailViewModel
    @State private var selectedSheet: AdminUserDetailSheet?

    var body: some View {
        List {
            content
        }
        .navigationTitle("Usuario")
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
        .alert("No se pudo completar", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $selectedSheet) { sheet in
            NavigationStack { sheetContent(sheet) }
        }
        .sheet(item: Binding(
            get: { viewModel.resetPasswordResult.map(PasswordSecretBox.init(result:)) },
            set: { _ in viewModel.dismissSecret() }
        )) { box in
            NavigationStack {
                AdminAccessSecretCard(
                    title: "Nueva contraseña temporal",
                    secret: box.result.temporaryPassword,
                    message: "Cópiala ahora. El usuario deberá cambiarla al iniciar sesión."
                )
                .padding()
                .navigationTitle("Contraseña reseteada")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { viewModel.dismissSecret() } } }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section { ProgressView("Cargando usuario…") }
        case .empty(let message):
            Section { EmptyStateView(systemImage: "person.crop.circle.badge.questionmark", title: "Sin usuario", message: message) }
        case .failed(let message):
            Section { ErrorStateView(title: "No se pudo cargar", message: message, retry: { Task { await viewModel.refresh() } }) }
        case .loaded(let user):
            Section("Resumen") {
                LabeledContent("Nombre", value: user.displayName)
                LabeledContent("Correo", value: user.email)
                if let phone = user.phone { LabeledContent("Teléfono", value: phone) }
                LabeledContent("Estado", value: user.statusLabel)
                LabeledContent("Membresía", value: user.membershipStatus.readableStatus)
                LabeledContent("Sesiones activas", value: "\(user.activeSessionCount)")
            }

            Section("Sesiones activas") {
                switch viewModel.sessionsState {
                case .idle, .loading:
                    ProgressView("Cargando sesiones…")
                case .empty(let message):
                    Text(message)
                        .foregroundStyle(.secondary)
                case .failed(let message):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No se pudo cargar sesiones.")
                            .font(.subheadline.weight(.semibold))
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Reintentar") { Task { await viewModel.refreshSessions() } }
                    }
                case .loaded(let sessions):
                    ForEach(sessions) { session in
                        AdminUserSessionRow(session: session)
                    }
                }
            }

            Section("Roles") {
                if user.roleNames.isEmpty {
                    Text("Sin roles asignados")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(user.roleNames, id: \.self) { name in
                        Label(name, systemImage: "person.badge.key")
                    }
                }
            }

            if !user.effectivePermissions.isEmpty {
                AdminEffectivePermissionsSection(permissionKeys: user.effectivePermissions)
            }

            Section("Acciones") {
                Button { selectedSheet = .edit } label: { Label("Editar datos y roles", systemImage: "square.and.pencil") }
                if user.isBlocked {
                    Button { selectedSheet = .unblock } label: { Label("Desbloquear usuario", systemImage: "lock.open") }
                } else {
                    Button(role: .destructive) { selectedSheet = .block } label: { Label("Bloquear usuario", systemImage: "lock") }
                }
                Button { selectedSheet = .resetPassword } label: { Label("Resetear contraseña", systemImage: "key") }
                Button(role: .destructive) { selectedSheet = .revokeSessions } label: { Label("Revocar sesiones", systemImage: "rectangle.portrait.and.arrow.right") }
            }

            if let blockedReason = user.blockedReason {
                Section("Motivo de bloqueo") {
                    Text(blockedReason)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func sheetContent(_ sheet: AdminUserDetailSheet) -> some View {
        switch sheet {
        case .edit:
            AdminUserEditView(viewModel: viewModel, onDone: { selectedSheet = nil })
        case .block:
            AdminUserReasonActionView(
                title: "Bloquear usuario",
                message: "El backend validará que no sea el último administrador activo y revocará sesiones si corresponde.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Bloquear",
                role: .destructive,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.blockUser(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        case .unblock:
            AdminUserReasonActionView(
                title: "Desbloquear usuario",
                message: "Restaurará el acceso del usuario en la organización activa.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Desbloquear",
                role: nil,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.unblockUser(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        case .resetPassword:
            AdminResetPasswordView(viewModel: viewModel, onDone: { selectedSheet = nil })
        case .revokeSessions:
            AdminUserReasonActionView(
                title: "Revocar sesiones",
                message: "El usuario deberá iniciar sesión nuevamente.",
                reason: $viewModel.actionReason,
                isMutating: viewModel.isMutating,
                actionTitle: "Revocar",
                role: .destructive,
                onCancel: { selectedSheet = nil },
                onConfirm: { await viewModel.revokeSessions(); if viewModel.errorMessage == nil { selectedSheet = nil } }
            )
        }
    }
}

private enum AdminUserDetailSheet: Identifiable {
    case edit
    case block
    case unblock
    case resetPassword
    case revokeSessions

    var id: String { String(describing: self) }
}

private struct AdminUserEditView: View {
    @ObservedObject var viewModel: AdminUserDetailViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Nombre", text: $viewModel.updateInput.displayName)
                Toggle("Quitar teléfono", isOn: $viewModel.updateInput.clearPhone)
                if !viewModel.updateInput.clearPhone {
                    TextField("Teléfono", text: $viewModel.updateInput.phone)
                        .keyboardType(.phonePad)
                }
            }

            Section("Roles") {
                RoleSelectionList(roles: viewModel.roles, selectedRoleIds: $viewModel.updateInput.roleIds)
            }

            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.updateInput.reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Editar usuario")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task {
                        await viewModel.saveUpdate()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canSaveUpdate || viewModel.isMutating)
            }
        }
    }
}

private struct AdminResetPasswordView: View {
    @ObservedObject var viewModel: AdminUserDetailViewModel
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Nueva contraseña") {
                SecureField("Opcional: dejar vacío para generar", text: $viewModel.resetTemporaryPassword)
                Toggle("Revocar sesiones activas", isOn: $viewModel.revokeSessionsOnReset)
            }
            Section("Auditoría") {
                TextField("Motivo", text: $viewModel.actionReason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle("Reset password")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onDone) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Resetear") {
                    Task {
                        await viewModel.resetPassword()
                        if viewModel.errorMessage == nil { onDone() }
                    }
                }
                .disabled(!viewModel.canRunAction || viewModel.isMutating)
            }
        }
    }
}

private struct AdminUserReasonActionView: View {
    let title: String
    let message: String
    @Binding var reason: String
    let isMutating: Bool
    let actionTitle: String
    let role: ButtonRole?
    let onCancel: () -> Void
    let onConfirm: () async -> Void

    var body: some View {
        Form {
            Section {
                Text(message)
                    .foregroundStyle(.secondary)
            }
            Section("Auditoría") {
                TextField("Motivo", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancelar", action: onCancel) }
            ToolbarItem(placement: .confirmationAction) {
                Button(actionTitle, role: role) { Task { await onConfirm() } }
                    .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isMutating)
            }
        }
    }
}

private struct AdminUserSessionRow: View {
    let session: AdminUserSession

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Label(session.displayTitle, systemImage: session.isActive ? "iphone.gen3.radiowaves.left.and.right" : "rectangle.portrait.slash")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                AdminAccessStatusBadge(text: session.statusLabel, systemImage: session.isActive ? "checkmark.circle.fill" : "xmark.circle")
            }

            if let deviceId = session.deviceId, !deviceId.isEmpty {
                Text(deviceId)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if !session.deviceSummary.isEmpty {
                Text(session.deviceSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Creada", value: session.createdAt)
            LabeledContent("Último uso", value: session.lastSeenAt ?? "—")
            LabeledContent("Expira", value: session.expiresAt)
        }
        .padding(.vertical, 4)
    }
}

private struct PasswordSecretBox: Identifiable {
    let id = UUID()
    let result: AdminResetPasswordResult
}


private struct AdminEffectivePermissionsSection: View {
    let permissionKeys: Set<String>
    @State private var searchText: String = ""
    @State private var showTechnicalCodes: Bool = false

    private var groups: [AdminEffectivePermissionGroup] {
        AdminEffectivePermissionDisplayMapper.groups(
            for: permissionKeys,
            query: searchText
        )
    }

    private var highRiskCount: Int {
        AdminEffectivePermissionDisplayMapper.descriptors(for: permissionKeys)
            .filter { $0.risk == .high || $0.risk == .critical }
            .count
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Label("\(permissionKeys.count) permisos", systemImage: "checklist.checked")
                    Spacer()
                    if highRiskCount > 0 {
                        AdminAccessStatusBadge(text: "\(highRiskCount) sensibles", systemImage: "exclamationmark.triangle.fill")
                    }
                }
                .font(.subheadline.weight(.semibold))

                Text("Estos son los permisos reales que el usuario hereda por sus roles. Se muestran agrupados para revisión operativa; los códigos técnicos quedan ocultos por defecto.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Buscar permiso", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(.quaternary.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Toggle("Ver códigos técnicos", isOn: $showTechnicalCodes)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Permisos efectivos")
        } footer: {
            Text("Para cambiar estos permisos, edita los roles asignados. Esta pantalla no edita permisos directamente.")
        }

        if groups.isEmpty {
            Section("Resultado") {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "Sin coincidencias",
                    message: "Ajusta la búsqueda o revisa los roles del usuario."
                )
            }
        } else {
            ForEach(groups) { group in
                Section {
                    AdminEffectivePermissionGroupView(
                        group: group,
                        showTechnicalCodes: showTechnicalCodes
                    )
                } header: {
                    Label(group.title, systemImage: group.systemImage)
                }
            }
        }
    }
}

private struct AdminEffectivePermissionGroupView: View {
    let group: AdminEffectivePermissionGroup
    let showTechnicalCodes: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.summary)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if group.highRiskCount > 0 {
                    AdminAccessStatusBadge(text: "\(group.highRiskCount) riesgo", systemImage: "exclamationmark.triangle.fill")
                }
            }

            ForEach(group.permissions) { permission in
                AdminEffectivePermissionRow(
                    descriptor: permission,
                    showTechnicalCode: showTechnicalCodes
                )

                if permission.id != group.permissions.last?.id {
                    Divider()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdminEffectivePermissionRow: View {
    let descriptor: AdminEffectivePermissionDescriptor
    let showTechnicalCode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: descriptor.systemImage)
                    .foregroundStyle(descriptor.risk.tint)
                    .frame(width: 20)

                Text(descriptor.title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                AdminAccessStatusBadge(
                    text: descriptor.kindLabel,
                    systemImage: descriptor.kindSystemImage
                )
            }

            Text(descriptor.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                AdminAccessStatusBadge(
                    text: descriptor.risk.label,
                    systemImage: descriptor.risk.systemImage
                )

                if descriptor.requiresAudit {
                    AdminAccessStatusBadge(text: "Auditado", systemImage: "doc.text.magnifyingglass")
                }

                if descriptor.requiresReason {
                    AdminAccessStatusBadge(text: "Motivo", systemImage: "text.bubble")
                }
            }

            if showTechnicalCode {
                Text(descriptor.code)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct AdminEffectivePermissionGroup: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let rank: Int
    let permissions: [AdminEffectivePermissionDescriptor]

    var summary: String {
        "\(permissions.count) \(permissions.count == 1 ? "permiso" : "permisos")"
    }

    var highRiskCount: Int {
        permissions.filter { $0.risk == .high || $0.risk == .critical }.count
    }
}

private struct AdminEffectivePermissionDescriptor: Identifiable, Equatable {
    var id: String { code }

    let code: String
    let title: String
    let description: String
    let groupId: String
    let groupTitle: String
    let groupSystemImage: String
    let groupRank: Int
    let kindLabel: String
    let kindSystemImage: String
    let systemImage: String
    let risk: AdminEffectivePermissionRisk
    let requiresAudit: Bool
    let requiresReason: Bool
}

private enum AdminEffectivePermissionRisk: String, Equatable {
    case low
    case medium
    case high
    case critical

    var label: String {
        switch self {
        case .low: "Bajo"
        case .medium: "Medio"
        case .high: "Alto"
        case .critical: "Crítico"
        }
    }

    var systemImage: String {
        switch self {
        case .low: "checkmark.circle"
        case .medium: "info.circle"
        case .high: "exclamationmark.triangle.fill"
        case .critical: "shield.lefthalf.filled.badge.exclamationmark"
        }
    }

    var tint: Color {
        switch self {
        case .low: .secondary
        case .medium: .blue
        case .high: .orange
        case .critical: .red
        }
    }
}

private enum AdminEffectivePermissionDisplayMapper {
    static func descriptors(for permissionKeys: Set<String>) -> [AdminEffectivePermissionDescriptor] {
        permissionKeys
            .map(descriptor(for:))
            .sorted {
                if $0.groupRank == $1.groupRank {
                    if $0.groupTitle == $1.groupTitle {
                        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    }
                    return $0.groupTitle.localizedCaseInsensitiveCompare($1.groupTitle) == .orderedAscending
                }
                return $0.groupRank < $1.groupRank
            }
    }

    static func groups(for permissionKeys: Set<String>, query: String) -> [AdminEffectivePermissionGroup] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = descriptors(for: permissionKeys).filter { descriptor in
            guard !cleanQuery.isEmpty else { return true }
            return descriptor.title.localizedCaseInsensitiveContains(cleanQuery)
                || descriptor.description.localizedCaseInsensitiveContains(cleanQuery)
                || descriptor.code.localizedCaseInsensitiveContains(cleanQuery)
                || descriptor.groupTitle.localizedCaseInsensitiveContains(cleanQuery)
        }

        let grouped = Dictionary(grouping: filtered, by: \.groupId)

        return grouped.map { groupId, permissions in
            let first = permissions[0]
            return AdminEffectivePermissionGroup(
                id: groupId,
                title: first.groupTitle,
                systemImage: first.groupSystemImage,
                rank: first.groupRank,
                permissions: permissions.sorted {
                    $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
            )
        }
        .sorted {
            if $0.rank == $1.rank {
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            return $0.rank < $1.rank
        }
    }

    private static func descriptor(for code: String) -> AdminEffectivePermissionDescriptor {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let group = groupInfo(for: normalizedCode)
        let exact = exactCopy[normalizedCode]
        let title = exact?.title ?? humanizedTitle(from: normalizedCode)
        let description = exact?.description ?? fallbackDescription(for: normalizedCode, title: title, groupTitle: group.title)
        let kind = kindInfo(for: normalizedCode)
        let risk = riskInfo(for: normalizedCode)

        return AdminEffectivePermissionDescriptor(
            code: normalizedCode,
            title: title,
            description: description,
            groupId: group.id,
            groupTitle: group.title,
            groupSystemImage: group.systemImage,
            groupRank: group.rank,
            kindLabel: kind.label,
            kindSystemImage: kind.systemImage,
            systemImage: kind.rowSystemImage,
            risk: risk,
            requiresAudit: requiresAudit(normalizedCode),
            requiresReason: requiresReason(normalizedCode)
        )
    }

    private static let exactCopy: [String: (title: String, description: String)] = [
        "*": ("Acceso total", "Permite todas las acciones disponibles. Debe reservarse para administradores de máxima confianza."),

        "activities.view": ("Ver actividades", "Permite consultar actividades económicas o líneas operativas configuradas."),
        "branches.view": ("Ver sucursales", "Permite consultar sucursales y puntos de operación."),
        "modules.view": ("Ver módulos", "Permite ver los módulos habilitados para el negocio."),
        "organization.view": ("Ver organización", "Permite consultar datos generales de la organización."),

        "catalog.view": ("Ver catálogo", "Permite consultar productos y servicios disponibles."),
        "catalog.local.view": ("Ver catálogo local", "Permite consultar productos adoptados o configurados para el negocio."),
        "catalog.manage": ("Administrar catálogo", "Permite crear, editar, activar o desactivar elementos del catálogo."),

        "cash.view": ("Ver caja", "Permite consultar estado general de caja."),
        "cash.session.view_current": ("Ver caja actual", "Permite consultar la sesión de caja abierta o vigente."),
        "cash.session.view_history": ("Ver historial de caja", "Permite revisar cierres y movimientos de caja anteriores."),
        "cash.session.open": ("Abrir caja", "Permite iniciar una sesión de caja."),
        "cash.session.close": ("Cerrar caja", "Permite cerrar caja y consolidar valores."),
        "cash.movement.create": ("Registrar movimiento de caja", "Permite registrar ingresos o egresos manuales."),

        "sales.view": ("Ver ventas", "Permite consultar ventas registradas."),
        "sales.create": ("Crear ventas", "Permite registrar ventas nuevas."),
        "sales.update": ("Editar ventas", "Permite modificar ventas dentro de los límites definidos."),
        "sales.confirm": ("Confirmar ventas", "Permite confirmar ventas y dejarlas operativas."),
        "sales.cancel": ("Cancelar ventas", "Permite cancelar ventas según reglas internas."),
        "sales.apply_discount": ("Aplicar descuentos", "Permite aplicar descuentos en ventas."),

        "customers.view": ("Ver clientes", "Permite consultar clientes."),
        "customers.create": ("Crear clientes", "Permite registrar nuevos clientes."),
        "customers.update": ("Editar clientes", "Permite modificar datos de clientes."),

        "documents.view": ("Ver documentos", "Permite consultar documentos generados."),
        "documents.download_pdf": ("Descargar PDF", "Permite descargar representaciones PDF o RIDE."),
        "documents.download_xml": ("Descargar XML", "Permite descargar XML del comprobante."),
        "documents.electronic_invoice.download_ride": ("Descargar RIDE", "Permite descargar el RIDE de factura electrónica."),
        "documents.electronic_invoice.issue": ("Emitir factura electrónica", "Permite iniciar emisión de factura electrónica desde flujos autorizados."),
        "documents.electronic_invoice.retry": ("Reintentar factura electrónica", "Permite reintentar recepción o autorización de comprobantes."),
        "documents.electronic_invoice.resend_email": ("Reenviar email de factura", "Permite reenviar comprobantes electrónicos por correo."),

        "reports.view": ("Ver reportes", "Permite consultar reportes operativos."),
        "reports.daily.view": ("Ver reporte diario", "Permite consultar reportes diarios de operación."),
        "exports.view": ("Ver exportaciones", "Permite consultar exportaciones generadas."),
        "exports.create": ("Generar exportaciones", "Permite crear archivos de exportación para operación o contador."),

        "receivables.view": ("Ver cuentas por cobrar", "Permite consultar saldos pendientes de clientes."),
        "receivables.create": ("Crear cuenta por cobrar", "Permite registrar ventas a crédito con cliente identificado."),
        "receivables.register_payment": ("Registrar abonos", "Permite registrar cobros sobre cuentas por cobrar."),

        "credentials.users.view": ("Ver usuarios", "Permite consultar usuarios y miembros."),
        "credentials.users.create": ("Crear usuarios", "Permite crear usuarios internos."),
        "credentials.users.invite": ("Invitar usuarios", "Permite enviar invitaciones a nuevos usuarios."),
        "credentials.users.update": ("Editar usuarios", "Permite modificar datos y roles de usuarios."),
        "credentials.users.block": ("Bloquear usuarios", "Permite bloquear acceso de usuarios."),
        "credentials.users.unblock": ("Desbloquear usuarios", "Permite restaurar acceso de usuarios."),
        "credentials.users.reset_password": ("Resetear contraseña", "Permite generar o forzar cambio de contraseña."),
        "credentials.sessions.revoke": ("Revocar sesiones", "Permite cerrar sesiones activas de usuarios."),
        "credentials.roles.view": ("Ver roles", "Permite consultar roles y permisos."),
        "credentials.roles.manage": ("Administrar roles", "Permite crear, editar o desactivar roles."),

        "audit.view": ("Ver auditoría", "Permite revisar eventos de auditoría."),
        "support.diagnostics.view": ("Ver diagnósticos", "Permite consultar diagnósticos técnicos de soporte.")
    ]

    private static func groupInfo(for code: String) -> (id: String, title: String, systemImage: String, rank: Int) {
        if code == "*" { return ("super", "Acceso total", "staroflife.shield", 0) }
        if code.hasPrefix("cash.") { return ("cash", "Caja", "cashregister", 10) }
        if code.hasPrefix("sales.") { return ("sales", "Ventas", "cart", 20) }
        if code.hasPrefix("receivables.") { return ("receivables", "Cuentas por cobrar", "creditcard", 30) }
        if code.hasPrefix("customers.") { return ("customers", "Clientes", "person.2", 40) }
        if code.hasPrefix("catalog.") { return ("catalog", "Catálogo", "shippingbox", 50) }
        if code.hasPrefix("inventory.") { return ("inventory", "Inventario", "archivebox", 60) }
        if code.hasPrefix("documents.") { return ("documents", "Documentos", "doc.text", 70) }
        if code.contains("electronic_invoice") || code.hasPrefix("sri.") || code.hasPrefix("tax.") { return ("fiscal", "Fiscal/SRI", "building.columns", 80) }
        if code.hasPrefix("reports.") { return ("reports", "Reportes", "chart.bar.doc.horizontal", 90) }
        if code.hasPrefix("exports.") { return ("exports", "Exportaciones", "square.and.arrow.down", 100) }
        if code.hasPrefix("credentials.") || code.hasPrefix("users.") || code.hasPrefix("roles.") { return ("access", "Usuarios y seguridad", "person.badge.key", 110) }
        if code.hasPrefix("audit.") { return ("audit", "Auditoría", "doc.text.magnifyingglass", 120) }
        if code.hasPrefix("support.") { return ("support", "Soporte", "stethoscope", 130) }
        if code.hasPrefix("organization.") || code.hasPrefix("branches.") || code.hasPrefix("activities.") || code.hasPrefix("modules.") { return ("configuration", "Configuración del negocio", "slider.horizontal.3", 140) }
        return ("other", "Otros permisos", "ellipsis.circle", 999)
    }

    private static func kindInfo(for code: String) -> (label: String, systemImage: String, rowSystemImage: String) {
        if code == "*" { return ("Admin", "crown", "crown.fill") }
        if code.contains("view") || code.contains("download") { return ("Lectura", "eye", "eye") }
        if code.contains("create") || code.contains("update") || code.contains("confirm") || code.contains("open") || code.contains("close") || code.contains("register") || code.contains("issue") || code.contains("resend") || code.contains("retry") {
            return ("Operación", "pencil.and.outline", "checkmark.circle")
        }
        if code.contains("manage") || code.contains("block") || code.contains("unblock") || code.contains("reset") || code.contains("revoke") || code.contains("delete") || code.contains("cancel") {
            return ("Admin", "lock.shield", "shield")
        }
        return ("Permiso", "checkmark.seal", "checkmark.seal")
    }

    private static func riskInfo(for code: String) -> AdminEffectivePermissionRisk {
        if code == "*" { return .critical }

        let criticalPatterns = [
            "roles.manage",
            "users.block",
            "users.unblock",
            "reset_password",
            "sessions.revoke",
            "delete"
        ]

        if criticalPatterns.contains(where: { code.contains($0) }) {
            return .critical
        }

        let highPatterns = [
            "electronic_invoice.issue",
            "electronic_invoice.retry",
            "cash.session.close",
            "sales.cancel",
            "credentials.",
            "audit.",
            "sri.",
            "tax."
        ]

        if highPatterns.contains(where: { code.contains($0) }) {
            return .high
        }

        let mediumPatterns = [
            "create",
            "update",
            "confirm",
            "open",
            "close",
            "register",
            "download_xml",
            "download_ride",
            "exports.create"
        ]

        if mediumPatterns.contains(where: { code.contains($0) }) {
            return .medium
        }

        return .low
    }

    private static func requiresAudit(_ code: String) -> Bool {
        code == "*"
            || code.contains("credentials.")
            || code.contains("electronic_invoice")
            || code.contains("cash.session.close")
            || code.contains("sales.cancel")
            || code.contains("audit.")
    }

    private static func requiresReason(_ code: String) -> Bool {
        code.contains("block")
            || code.contains("unblock")
            || code.contains("reset_password")
            || code.contains("sessions.revoke")
            || code.contains("sales.cancel")
    }

    private static func fallbackDescription(for code: String, title: String, groupTitle: String) -> String {
        if code.contains("view") { return "Permite consultar información de \(groupTitle.lowercased())." }
        if code.contains("download") { return "Permite descargar información o archivos relacionados con \(groupTitle.lowercased())." }
        if code.contains("create") { return "Permite crear registros en \(groupTitle.lowercased())." }
        if code.contains("update") { return "Permite modificar registros en \(groupTitle.lowercased())." }
        if code.contains("manage") { return "Permite administrar opciones de \(groupTitle.lowercased())." }
        return "Permiso operativo relacionado con \(groupTitle.lowercased()). Código: \(code)."
    }

    private static func humanizedTitle(from code: String) -> String {
        let tokens = code
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map(String.init)

        let translated = tokens.map { token -> String in
            switch token {
            case "view": return "ver"
            case "create": return "crear"
            case "update": return "editar"
            case "delete": return "eliminar"
            case "download": return "descargar"
            case "manage": return "administrar"
            case "register": return "registrar"
            case "payment": return "pago"
            case "payments": return "pagos"
            case "session": return "sesión"
            case "sessions": return "sesiones"
            case "current": return "actual"
            case "history": return "historial"
            case "electronic": return "electrónica"
            case "invoice": return "factura"
            case "customers": return "clientes"
            case "customer": return "cliente"
            case "documents": return "documentos"
            case "catalog": return "catálogo"
            case "local": return "local"
            case "cash": return "caja"
            case "roles": return "roles"
            case "users": return "usuarios"
            case "credentials": return "credenciales"
            case "organization": return "organización"
            case "branches": return "sucursales"
            case "activities": return "actividades"
            case "modules": return "módulos"
            default: return token
            }
        }

        let raw = translated.joined(separator: " ")
        guard let first = raw.first else { return code }
        return first.uppercased() + raw.dropFirst()
    }
}

