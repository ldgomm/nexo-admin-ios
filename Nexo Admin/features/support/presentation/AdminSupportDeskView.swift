//
//  AdminSupportDeskView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 1/7/26.
//

import SwiftUI

struct AdminSupportDeskView: View {
    @StateObject private var viewModel: AdminSupportDeskViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: AdminSupportDeskViewModel())
    }

    @MainActor
    init(viewModel: AdminSupportDeskViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    supportHeaderCard
                        .adminSupportSurface(isHero: true)

                    if let error = viewModel.errorMessage, !viewModel.lastTicketLoadSucceeded {
                        AdminSupportNoticeCard(
                            title: "No se pudo cargar soporte",
                            message: error,
                            systemImage: "exclamationmark.triangle",
                            style: .error
                        )
                    }

                    supportInboxCard
                        .adminSupportSurface()

                    selectedTicketCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Soporte")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .task { await viewModel.loadTickets() }
            .overlay {
                if viewModel.isLoading && viewModel.tickets.isEmpty {
                    ProgressView("Cargando soporte…")
                        .padding(18)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        }
                }
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.loadTickets() }
        } label: {
            if viewModel.isLoading {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel("Actualizar tickets de soporte")
    }

    private var supportHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lifepreserver.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Support desk")
                        .font(.title3.weight(.bold))

                    Text("Bandeja interna para atender tickets con contexto sanitizado y acciones controladas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                AdminSupportMiniMetric(
                    title: "Tickets",
                    value: "\(viewModel.tickets.count)",
                    systemImage: "tray.full"
                )

                AdminSupportMiniMetric(
                    title: "Selección",
                    value: viewModel.selectedTicket == nil ? "—" : "Activa",
                    systemImage: viewModel.selectedTicket == nil ? "circle" : "checkmark.circle"
                )
            }
        }
    }

    private var supportInboxCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            filtersHeader

            VStack(spacing: 10) {
                AdminSupportInputRow(
                    title: "Estado",
                    placeholder: "Ej. open",
                    text: Binding(
                        get: { viewModel.statusFilter ?? "" },
                        set: { viewModel.statusFilter = $0.trimmed.nilIfBlank }
                    ),
                    systemImage: "tag"
                )

                AdminSupportInputRow(
                    title: "Prioridad",
                    placeholder: "Ej. high",
                    text: Binding(
                        get: { viewModel.priorityFilter ?? "" },
                        set: { viewModel.priorityFilter = $0.trimmed.nilIfBlank }
                    ),
                    systemImage: "flag"
                )

                AdminSupportInputRow(
                    title: "Organización",
                    placeholder: "ID o nombre",
                    text: Binding(
                        get: { viewModel.organizationFilter ?? "" },
                        set: { viewModel.organizationFilter = $0.trimmed.nilIfBlank }
                    ),
                    systemImage: "building.2"
                )
            }

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.loadTickets() }
                } label: {
                    AdminSupportActionLabel(
                        title: "Aplicar filtros",
                        systemImage: "line.3.horizontal.decrease.circle",
                        isLoading: viewModel.isLoading
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)

                Button {
                    viewModel.statusFilter = nil
                    viewModel.priorityFilter = nil
                    viewModel.organizationFilter = nil
                    Task { await viewModel.loadTickets() }
                } label: {
                    Label("Limpiar", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
            }

            Divider().padding(.vertical, 2)

            ticketsList
        }
    }

    private var filtersHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Bandeja y filtros")
                    .font(.headline)

                Text("Filtra lo necesario y selecciona un ticket para gestionarlo abajo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var ticketsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tickets")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(viewModel.tickets.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color(uiColor: .tertiarySystemGroupedBackground))
                    }
            }

            if viewModel.tickets.isEmpty {
                AdminSupportEmptyState(
                    title: "No hay tickets visibles",
                    message: "Ajusta filtros o actualiza la bandeja para volver a consultar.",
                    systemImage: "tray"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.tickets) { ticket in
                        Button {
                            Task { await viewModel.selectTicket(ticket) }
                        } label: {
                            AdminSupportTicketRow(
                                subject: ticket.subject,
                                priority: ticket.priority,
                                status: ticket.status,
                                requester: ticket.requesterLabel,
                                isSelected: viewModel.selectedTicket?.id == ticket.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectedTicketCard: some View {
        if let ticket = viewModel.selectedTicket {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 38, height: 38)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.12))
                            }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(ticket.subject)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(ticket.requesterLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        AdminSupportBadge(text: ticket.status, systemImage: "tag")
                        AdminSupportBadge(text: ticket.priority, systemImage: "flag")
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    AdminSupportBlockHeader(
                        title: "Contexto sanitizado",
                        subtitle: "Solo se muestra información preparada para soporte.",
                        systemImage: "shield.lefthalf.filled"
                    )

                    if ticket.contextRefs.isEmpty {
                        AdminSupportEmptyState(
                            title: "Sin contexto adjunto",
                            message: "Este ticket no trae referencias adicionales.",
                            systemImage: "shield"
                        )
                    } else {
                        VStack(spacing: 8) {
                            ForEach(ticket.contextRefs) { context in
                                AdminSupportContextRow(
                                    label: context.label,
                                    value: context.sanitizedDisplayValue,
                                    redactionStatus: context.redactionStatus
                                )
                            }
                        }
                    }
                }

                Divider()

                communicationBlock

                Divider()

                resolutionBlock
            }
            .adminSupportSurface()
        } else {
            AdminSupportEmptyState(
                title: "Selecciona un ticket",
                message: "Aquí aparecerán el contexto sanitizado, respuesta, nota interna y acciones de resolución.",
                systemImage: "doc.text.magnifyingglass"
            )
            .adminSupportSurface()
        }
    }

    private var communicationBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            AdminSupportBlockHeader(
                title: "Comunicación",
                subtitle: "Respuesta visible para Business y nota interna separada.",
                systemImage: "bubble.left.and.bubble.right"
            )

            AdminSupportTextEditorCard(
                title: "Respuesta para Business",
                placeholder: "Escribe la respuesta visible para el negocio",
                text: $viewModel.replyBody,
                systemImage: "paperplane"
            )

            Button {
                Task { await viewModel.replyToTicket() }
            } label: {
                AdminSupportActionLabel(title: "Responder ticket", systemImage: "paperplane.fill", isLoading: false)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.replyBody.trimmed.isEmpty)

            AdminSupportTextEditorCard(
                title: "Nota interna",
                placeholder: "Escribe una nota privada de soporte",
                text: $viewModel.internalNoteBody,
                systemImage: "lock.doc"
            )

            Button {
                Task { await viewModel.addInternalNote() }
            } label: {
                Label("Agregar nota interna", systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.internalNoteBody.trimmed.isEmpty)
        }
    }

    private var resolutionBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            AdminSupportBlockHeader(
                title: "Resolución",
                subtitle: "Cierra el ciclo solo cuando el ticket esté atendido.",
                systemImage: "checkmark.seal"
            )

            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.resolveTicket() }
                } label: {
                    Label("Resolver", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    Task { await viewModel.closeTicket() }
                } label: {
                    Label("Cerrar", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

private struct AdminSupportMiniMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }
}

private struct AdminSupportInputRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }
}

private struct AdminSupportTicketRow: View {
    let subject: String
    let priority: String
    let status: String
    let requester: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(subject)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(requester)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    AdminSupportBadge(text: status, systemImage: "tag")
                    AdminSupportBadge(text: priority, systemImage: "flag")
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(uiColor: .tertiarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.22) : Color.clear, lineWidth: 1)
        }
    }
}

private struct AdminSupportBadge: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
    }
}

private struct AdminSupportContextRow: View {
    let label: String
    let value: String
    let redactionStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(redactionStatus)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    }
            }

            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }
}

private struct AdminSupportTextEditorCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }
}

private struct AdminSupportBlockHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct AdminSupportActionLabel: View {
    let title: String
    let systemImage: String
    let isLoading: Bool

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            if isLoading {
                ProgressView().controlSize(.small)
            } else {
                Label(title, systemImage: systemImage)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct AdminSupportEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }
}

private enum AdminSupportNoticeStyle {
    case info
    case error

    var tint: Color {
        switch self {
        case .info:
            return .accentColor
        case .error:
            return .red
        }
    }
}

private struct AdminSupportNoticeCard: View {
    let title: String
    let message: String
    let systemImage: String
    let style: AdminSupportNoticeStyle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(style.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(style.tint.opacity(0.10))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(style.tint.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct AdminSupportSurfaceModifier: ViewModifier {
    let isHero: Bool

    func body(content: Content) -> some View {
        content
            .padding(isHero ? 18 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: isHero ? 24 : 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: isHero ? 24 : 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(isHero ? 0.06 : 0.035), radius: isHero ? 13 : 8, x: 0, y: isHero ? 7 : 4)
    }
}

private extension View {
    func adminSupportSurface(isHero: Bool = false) -> some View {
        modifier(AdminSupportSurfaceModifier(isHero: isHero))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
