//
//  AdminSupplierViews.swift
//  Nexo Admin
//
//  27R.N.2 — Supplier master list, detail, edit and status controls.
//

import SwiftUI

struct AdminSupplierListView: View {
    @StateObject private var viewModel: AdminSupplierViewModel
    @State private var showingCreate = false

    init(viewModel: AdminSupplierViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            filterSection
            feedbackSection
            supplierSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Proveedores")
        .searchable(text: $viewModel.query, prompt: "Nombre o identificación")
        .onSubmit(of: .search) { Task { await viewModel.refresh() } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.canCreate {
                    Button { showingCreate = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Crear proveedor")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                AdminSupplierEditorView(viewModel: viewModel, supplier: nil)
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .refreshable { await viewModel.refresh() }
    }

    private var filterSection: some View {
        Section("Filtros del backend") {
            Picker("Estado", selection: $viewModel.statusFilter) {
                ForEach(AdminSupplierStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .onChange(of: viewModel.statusFilter) { _, _ in
                Task { await viewModel.refresh() }
            }

            TextField("Categoría", text: $viewModel.category)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { Task { await viewModel.refresh() } }

            if viewModel.hasActiveFilters {
                Button("Limpiar filtros") {
                    Task { await viewModel.clearFilters() }
                }
            }
        }
    }

    @ViewBuilder
    private var feedbackSection: some View {
        if let error = viewModel.errorMessage {
            Section {
                NexoAdminUXInlineMessage(
                    title: "No se pudo completar la operación",
                    message: error,
                    tone: .danger
                )
            }
        } else if let success = viewModel.successMessage {
            Section {
                NexoAdminUXInlineMessage(
                    title: "Proveedor actualizado",
                    message: success,
                    tone: .success
                )
            }
        }
    }

    @ViewBuilder
    private var supplierSection: some View {
        Section("Resultados") {
            if viewModel.isLoading && viewModel.suppliers.isEmpty {
                HStack {
                    Spacer()
                    ProgressView("Cargando proveedores…")
                    Spacer()
                }
            } else if viewModel.suppliers.isEmpty {
                EmptyStateView(
                    systemImage: "building.2",
                    title: "Sin proveedores",
                    message: viewModel.hasActiveFilters
                        ? "No hay proveedores que coincidan con los filtros enviados al backend."
                        : "Crea el primer proveedor para iniciar el flujo de compras."
                )
            } else {
                ForEach(viewModel.suppliers) { supplier in
                    NavigationLink {
                        AdminSupplierDetailView(viewModel: viewModel, supplierId: supplier.id)
                    } label: {
                        AdminSupplierRow(supplier: supplier)
                    }
                    .task { await viewModel.loadMoreIfNeeded(current: supplier) }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView("Cargando más…")
                        Spacer()
                    }
                } else if viewModel.hasMore {
                    Button("Cargar más") { Task { await viewModel.loadNextPage() } }
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct AdminSupplierRow: View {
    let supplier: AdminSupplier

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(supplier.displayName)
                    .font(.headline)
                Spacer(minLength: 8)
                NexoAdminUXStatusBadge(
                    title: supplier.status.title,
                    systemImage: supplier.status.systemImage,
                    tint: supplier.status.tint
                )
            }

            if let secondaryName = supplier.secondaryName {
                Text(secondaryName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Label(supplier.paymentTerms.title, systemImage: "calendar.badge.clock")
                if !supplier.categories.isEmpty {
                    Label(supplier.categories.joined(separator: ", "), systemImage: "tag")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct AdminSupplierDetailView: View {
    @ObservedObject var viewModel: AdminSupplierViewModel
    let supplierId: String

    @State private var showingEdit = false
    @State private var showingStatus = false

    var body: some View {
        Group {
            if let supplier = viewModel.supplier(id: supplierId) {
                supplierList(supplier)
            } else {
                NexoAdminUXEmptyState(
                    systemImage: "building.2.crop.circle",
                    title: "Proveedor fuera de la consulta",
                    message: "El proveedor ya no coincide con el filtro actual. Vuelve a la lista para continuar."
                )
                .padding(20)
            }
        }
        .navigationTitle(viewModel.supplier(id: supplierId)?.displayName ?? "Proveedor")
        .sheet(isPresented: $showingEdit) {
            if let supplier = viewModel.supplier(id: supplierId) {
                NavigationStack {
                    AdminSupplierEditorView(viewModel: viewModel, supplier: supplier)
                }
            }
        }
        .sheet(isPresented: $showingStatus) {
            if let supplier = viewModel.supplier(id: supplierId) {
                NavigationStack {
                    AdminSupplierStatusView(viewModel: viewModel, supplier: supplier)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func supplierList(_ supplier: AdminSupplier) -> some View {
        List {
            Section("Identidad") {
                LabeledContent("Razón social", value: supplier.legalName)
                if let tradeName = supplier.tradeName {
                    LabeledContent("Nombre comercial", value: tradeName)
                }
                LabeledContent("Estado", value: supplier.status.title)
                LabeledContent("Moneda", value: supplier.defaultCurrency)
                if let type = supplier.identificationType {
                    LabeledContent("Tipo de identificación", value: type.title)
                }
                if let number = supplier.identificationNumber {
                    LabeledContent("Identificación", value: number)
                        .textSelection(.enabled)
                }
            }

            Section("Condiciones de pago") {
                LabeledContent("Condición", value: supplier.paymentTerms.title)
                if let notes = supplier.paymentTerms.notes {
                    Text(notes).foregroundStyle(.secondary)
                }
            }

            if supplier.sensitiveFieldsAvailable {
                Section("Contacto y ubicación") {
                    optionalContent("Correo", supplier.email)
                    optionalContent("Teléfono", supplier.phone)
                    optionalContent("Dirección", supplier.address)
                    optionalContent("Notas", supplier.notes)
                }

                if let contacts = supplier.contacts, !contacts.isEmpty {
                    Section("Contactos") {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(contact.name).font(.headline)
                                    if contact.isPrimary {
                                        Text("Principal")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.blue)
                                    }
                                }
                                if let role = contact.role { Text(role).font(.subheadline) }
                                if let email = contact.email { Text(email).font(.caption).foregroundStyle(.secondary) }
                                if let phone = contact.phone { Text(phone).font(.caption).foregroundStyle(.secondary) }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            } else {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Datos sensibles protegidos",
                        message: "El backend ocultó identificación, contacto, dirección y notas. Se requiere suppliers.sensitive_view.",
                        tone: .warning
                    )
                }
            }

            if !supplier.categories.isEmpty {
                Section("Categorías") {
                    Text(supplier.categories.joined(separator: ", "))
                }
            }

            Section("Auditoría y concurrencia") {
                LabeledContent("Versión", value: String(supplier.version))
                LabeledContent("Creado", value: supplier.createdAt)
                LabeledContent("Creado por", value: supplier.createdBy)
                LabeledContent("Actualizado", value: supplier.updatedAt)
                LabeledContent("Actualizado por", value: supplier.updatedBy)
            }

            if viewModel.canUpdate || viewModel.canManageStatus {
                Section("Acciones") {
                    if viewModel.canUpdate {
                        Button("Editar proveedor") { showingEdit = true }
                    }
                    if viewModel.canManageStatus {
                        Button("Cambiar estado") { showingStatus = true }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func optionalContent(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmedOrNil {
            LabeledContent(label, value: value)
        }
    }
}

struct AdminSupplierEditorView: View {
    @ObservedObject var viewModel: AdminSupplierViewModel
    let supplier: AdminSupplier?
    @Environment(\.dismiss) private var dismiss

    @State private var legalName: String
    @State private var tradeName: String
    @State private var identificationType: String
    @State private var identificationNumber: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var categories: String
    @State private var paymentMode: AdminSupplierPaymentTermsMode
    @State private var netDays: Int
    @State private var paymentLabel: String
    @State private var paymentNotes: String
    @State private var notes: String
    @State private var contacts: [AdminSupplierContactInput]
    @State private var idempotencyKey: String

    init(viewModel: AdminSupplierViewModel, supplier: AdminSupplier?) {
        self.viewModel = viewModel
        self.supplier = supplier
        _legalName = State(initialValue: supplier?.legalName ?? "")
        _tradeName = State(initialValue: supplier?.tradeName ?? "")
        _identificationType = State(initialValue: supplier?.identificationType?.rawValue ?? "NONE")
        _identificationNumber = State(initialValue: supplier?.identificationNumber ?? "")
        _email = State(initialValue: supplier?.email ?? "")
        _phone = State(initialValue: supplier?.phone ?? "")
        _address = State(initialValue: supplier?.address ?? "")
        _categories = State(initialValue: supplier?.categories.joined(separator: ", ") ?? "")
        _paymentMode = State(initialValue: supplier?.paymentTerms.mode ?? .immediate)
        _netDays = State(initialValue: supplier?.paymentTerms.netDays ?? 30)
        _paymentLabel = State(initialValue: supplier?.paymentTerms.label ?? "")
        _paymentNotes = State(initialValue: supplier?.paymentTerms.notes ?? "")
        _notes = State(initialValue: supplier?.notes ?? "")
        _contacts = State(initialValue: supplier?.contacts?.map {
            AdminSupplierContactInput(
                serverId: $0.id,
                name: $0.name,
                role: $0.role ?? "",
                email: $0.email ?? "",
                phone: $0.phone ?? "",
                isPrimary: $0.isPrimary,
                notes: $0.notes ?? ""
            )
        } ?? [])
        _idempotencyKey = State(initialValue: UUID().uuidString.lowercased())
    }

    var body: some View {
        Form {
            if supplier != nil && !viewModel.canViewSensitive {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "Edición sensible no disponible",
                        message: "Sin suppliers.sensitive_view no es seguro editar: los campos ocultos podrían borrarse. Solicita ese permiso y vuelve a cargar.",
                        tone: .danger
                    )
                }
            }

            Section("Identidad") {
                TextField("Razón social", text: $legalName)
                TextField("Nombre comercial", text: $tradeName)
                Picker("Tipo de identificación", selection: $identificationType) {
                    Text("Sin identificación").tag("NONE")
                    ForEach(AdminSupplierIdentificationType.allCases) { type in
                        Text(type.title).tag(type.rawValue)
                    }
                }
                if identificationType != "NONE" {
                    TextField("Número de identificación", text: $identificationNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }

            Section("Contacto y ubicación") {
                TextField("Correo", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                TextField("Teléfono", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Dirección", text: $address, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Clasificación") {
                TextField("Categorías separadas por coma", text: $categories, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Condiciones de pago") {
                Picker("Modalidad", selection: $paymentMode) {
                    ForEach(AdminSupplierPaymentTermsMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                if paymentMode == .netDays {
                    Stepper("Días de crédito: \(netDays)", value: $netDays, in: 1...365)
                }
                if paymentMode == .custom {
                    TextField("Descripción de la condición", text: $paymentLabel)
                }
                TextField("Notas de pago", text: $paymentNotes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Contactos") {
                ForEach($contacts) { $contact in
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Nombre", text: $contact.name)
                        TextField("Cargo", text: $contact.role)
                        TextField("Correo", text: $contact.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        TextField("Teléfono", text: $contact.phone)
                            .keyboardType(.phonePad)
                        Toggle("Contacto principal", isOn: $contact.isPrimary)
                            .onChange(of: contact.isPrimary) { _, isPrimary in
                                if isPrimary { makePrimary(contact.localId) }
                            }
                        TextField("Notas", text: $contact.notes, axis: .vertical)
                            .lineLimit(1...3)
                        Button("Eliminar contacto", role: .destructive) {
                            contacts.removeAll(where: { $0.localId == contact.localId })
                        }
                    }
                    .padding(.vertical, 5)
                }

                Button {
                    contacts.append(AdminSupplierContactInput())
                } label: {
                    Label("Añadir contacto", systemImage: "person.badge.plus")
                }
            }

            Section("Notas internas") {
                TextField("Notas", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            if let error = viewModel.errorMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "No se pudo guardar",
                        message: error,
                        tone: .danger
                    )
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving { ProgressView().padding(.trailing, 6) }
                        Text(supplier == nil ? "Crear proveedor" : "Guardar proveedor")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving || (supplier != nil && !viewModel.canViewSensitive))
            }
        }
        .navigationTitle(supplier == nil ? "Nuevo proveedor" : "Editar proveedor")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
        }
        .onAppear { viewModel.clearMessages() }
    }

    private func makePrimary(_ id: UUID) {
        for index in contacts.indices {
            contacts[index].isPrimary = contacts[index].localId == id
        }
    }

    private func save() async {
        let parsedCategories = categories
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .compactMap(\.trimmedOrNil)

        let input = AdminSupplierWriteInput(
            legalName: legalName,
            tradeName: tradeName,
            identificationType: AdminSupplierIdentificationType(rawValue: identificationType),
            identificationNumber: identificationType == "NONE" ? "" : identificationNumber,
            email: email,
            phone: phone,
            address: address,
            categories: parsedCategories,
            contacts: contacts,
            paymentTermsMode: paymentMode,
            netDays: paymentMode == .netDays ? netDays : nil,
            paymentTermsLabel: paymentLabel,
            paymentTermsNotes: paymentNotes,
            notes: notes,
            expectedVersion: supplier?.version,
            idempotencyKey: idempotencyKey
        )

        let saved: Bool
        if let supplier {
            saved = await viewModel.update(id: supplier.id, input: input)
        } else {
            saved = await viewModel.create(input)
        }
        if saved { dismiss() }
    }
}

struct AdminSupplierStatusView: View {
    @ObservedObject var viewModel: AdminSupplierViewModel
    let supplier: AdminSupplier
    @Environment(\.dismiss) private var dismiss

    @State private var status: AdminSupplierStatus
    @State private var reason = ""
    @State private var idempotencyKey = UUID().uuidString.lowercased()

    init(viewModel: AdminSupplierViewModel, supplier: AdminSupplier) {
        self.viewModel = viewModel
        self.supplier = supplier
        _status = State(initialValue: supplier.status == .active ? .inactive : .active)
    }

    var body: some View {
        Form {
            Section("Estado actual") {
                LabeledContent("Proveedor", value: supplier.displayName)
                LabeledContent("Estado", value: supplier.status.title)
                LabeledContent("Versión", value: String(supplier.version))
            }

            Section("Nuevo estado") {
                Picker("Estado", selection: $status) {
                    ForEach(AdminSupplierStatus.allCases.filter { $0 != supplier.status }) { value in
                        Text(value.title).tag(value)
                    }
                }
                TextField("Motivo obligatorio", text: $reason, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let error = viewModel.errorMessage {
                Section {
                    NexoAdminUXInlineMessage(
                        title: "No se pudo cambiar el estado",
                        message: error,
                        tone: .danger
                    )
                }
            }

            Section {
                Button {
                    Task { await changeStatus() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving { ProgressView().padding(.trailing, 6) }
                        Text("Confirmar cambio").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle("Cambiar estado")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
        }
        .onAppear { viewModel.clearMessages() }
    }

    private func changeStatus() async {
        let changed = await viewModel.changeStatus(
            id: supplier.id,
            input: AdminSupplierStatusInput(
                status: status,
                reason: reason,
                expectedVersion: supplier.version,
                idempotencyKey: idempotencyKey
            )
        )
        if changed { dismiss() }
    }
}

private extension AdminSupplierStatus {
    var tint: Color {
        switch self {
        case .active: return .green
        case .inactive: return .orange
        case .blocked: return .red
        }
    }
}
