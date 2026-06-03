//
//  OrganizationSwitcherButton.swift
//  Nexo Admin
//
//  Created by José Ruiz on 28/5/26.
//

import SwiftUI

struct OrganizationSwitcherButton: View {
    @ObservedObject var sessionStore: AuthSessionStore
    let onChangeOrganization: () -> Void

    private var title: String {
        guard let organization = sessionStore.activeOrganization else { return "Sin organización" }
        return organization.commercialName.isEmpty ? organization.legalName : organization.commercialName
    }

    private var subtitle: String {
        guard let organization = sessionStore.activeOrganization else { return "Seleccionar organización" }
        return "\(organization.taxId) · \(sessionStore.organizations.count) org."
    }

    var body: some View {
        Button(action: onChangeOrganization) {
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cambiar organización")
    }
}
