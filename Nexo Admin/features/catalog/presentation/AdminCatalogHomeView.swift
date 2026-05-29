//
//  AdminCatalogHomeView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminCatalogHomeView: View {
    @ObservedObject var sessionStore: AuthSessionStore
    @StateObject private var viewModel: AdminCatalogViewModel

    init(sessionStore: AuthSessionStore, repository: any AdminCatalogRepository) {
        self.sessionStore = sessionStore
        _viewModel = StateObject(wrappedValue: AdminCatalogViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            PermissionGate(
                permissions: sessionStore.effectivePermissions,
                required: [
                    PermissionCatalog.catalogLocalView,
                    PermissionCatalog.catalogLocalCopyFromMaster,
                    PermissionCatalog.catalogLocalRequestNewItem
                ]
            ) {
                content
                    .navigationTitle("Catálogo")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task { await viewModel.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
            } fallback: {
                EmptyStateView(
                    systemImage: "lock.fill",
                    title: "Sin permiso",
                    message: "Tu usuario no tiene permisos efectivos para administrar catálogo. El backend también validará cada acción."
                )
                .navigationTitle("Catálogo")
            }
        }
        .task { await viewModel.load() }
        .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Listo", isPresented: Binding(get: { viewModel.successMessage != nil }, set: { if !$0 { viewModel.successMessage = nil } })) {
            Button("OK", role: .cancel) { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if viewModel.isLoading && viewModel.localItems.isEmpty {
                    ProgressView("Cargando catálogo…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    metrics
                    shortcuts
                    recentItems
                    recentRequests
                }
            }
            .padding()
        }
        .refreshable { await viewModel.refresh() }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AdminCatalogMetricCard(
                title: "Ítems activos",
                value: "\(viewModel.activeItemsCount)",
                subtitle: "Listos para vender",
                systemImage: "checkmark.seal"
            )
            AdminCatalogMetricCard(
                title: "Solicitudes",
                value: "\(viewModel.pendingRequestsCount)",
                subtitle: "Pendientes o con info requerida",
                systemImage: "tray.full"
            )
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            AdminCatalogSectionHeader(
                title: "Acciones rápidas",
                subtitle: "Prepara catálogo local sin contaminar el maestro.",
                systemImage: "bolt.fill"
            )
            VStack(spacing: 10) {
                NavigationLink {
                    AdminCatalogLocalItemsView(sessionStore: sessionStore, viewModel: viewModel)
                } label: {
                    shortcutLabel("Catálogo local", "Buscar, editar precio, activar o desactivar", "square.grid.2x2")
                }
                NavigationLink {
                    AdminCatalogMasterSearchView(sessionStore: sessionStore, viewModel: viewModel)
                } label: {
                    shortcutLabel("Copiar desde maestro", "Buscar plantillas gobernadas y copiarlas", "doc.on.doc")
                }
                NavigationLink {
                    AdminCatalogRequestsView(sessionStore: sessionStore, viewModel: viewModel)
                } label: {
                    shortcutLabel("Solicitudes", "Pedir productos o servicios que no existen", "plus.message")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var recentItems: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminCatalogSectionHeader(
                title: "Catálogo local reciente",
                subtitle: "Copias propias del negocio con precio y tax profile local.",
                systemImage: "shippingbox.fill"
            )
            if viewModel.localItems.isEmpty {
                EmptyStateView(systemImage: "square.grid.2x2", title: "Sin ítems locales", message: "Busca en el catálogo maestro y copia los productos o servicios que el negocio venderá.")
                    .frame(minHeight: 160)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.localItems.prefix(5)) { item in
                        NavigationLink {
                            AdminCatalogLocalItemDetailView(sessionStore: sessionStore, viewModel: viewModel, item: item)
                        } label: {
                            AdminCatalogItemRow(item: item)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    private var recentRequests: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminCatalogSectionHeader(
                title: "Solicitudes recientes",
                subtitle: "Pedidos para crear o vincular nuevos productos/servicios.",
                systemImage: "tray.full.fill"
            )
            if viewModel.requests.isEmpty {
                EmptyStateView(systemImage: "tray", title: "Sin solicitudes", message: "Cuando un producto no exista en el maestro, crea una solicitud para mantener datos limpios.")
                    .frame(minHeight: 130)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.requests.prefix(3)) { request in
                        NavigationLink {
                            AdminCatalogRequestDetailView(viewModel: viewModel, request: request)
                        } label: {
                            AdminCatalogRequestRow(request: request)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }

    private func shortcutLabel(_ title: String, _ subtitle: String, _ systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
