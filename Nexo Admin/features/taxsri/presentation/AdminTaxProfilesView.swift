//
//  AdminTaxProfilesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 2/6/26.
//

import SwiftUI

struct AdminTaxProfilesView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel

    private var sortedProfiles: [AdminTaxProfile] {
        viewModel.taxProfiles.sorted { lhs, rhs in
            if lhs.status.lowercased() != rhs.status.lowercased() {
                return lhs.status.lowercased() < rhs.status.lowercased()
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        AdminTaxSriSectionCard(title: "Perfiles tributarios", subtitle: "Tarifas, tratamientos y códigos SRI consumidos desde backend", systemImage: "list.bullet.rectangle") {
            if sortedProfiles.isEmpty {
                Text("No hay perfiles tributarios disponibles.").foregroundStyle(.secondary)
            } else {
                ForEach(sortedProfiles) { profile in
                    NavigationLink {
                        AdminTaxProfileDetailView(profile: profile)
                    } label: {
                        AdminTaxProfileRow(profile: profile)
                    }
                    Divider()
                }
            }
        }
    }
}

private struct AdminTaxProfileRow: View {
    let profile: AdminTaxProfile

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(.subheadline.weight(.semibold))

                    if profile.isTourismReducedIva {
                        AdminTaxSriMiniBadge(text: "Turismo 8%")
                    } else if profile.isConstructionReducedIva {
                        AdminTaxSriMiniBadge(text: "Construcción")
                    } else if profile.isInternalOnly {
                        AdminTaxSriMiniBadge(text: "Interno")
                    }
                }

                Text("\(profile.taxName) \(profile.displayRate) • \(profile.displaySriCodes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(profile.treatment)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)

                if let eligibilitySummary = profile.eligibilitySummary {
                    Label(eligibilitySummary, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            AdminTaxSriStatusBadge(text: profile.status)
        }
        .contentShape(Rectangle())
    }
}

struct AdminTaxProfileDetailView: View {
    let profile: AdminTaxProfile

    var body: some View {
        List {
            Section("Perfil") {
                AdminTaxSriInfoRow(title: "Código", value: profile.code, systemImage: "number")
                AdminTaxSriInfoRow(title: "Nombre", value: profile.name, systemImage: "tag")
                AdminTaxSriInfoRow(title: "Descripción", value: profile.description, systemImage: "text.alignleft")
                AdminTaxSriInfoRow(title: "Estado", value: profile.status, systemImage: "circle.fill")
                AdminTaxSriInfoRow(title: "Editable", value: profile.editable ? "Sí" : "No", systemImage: "slider.horizontal.3")
            }

            Section("Tratamiento tributario") {
                AdminTaxSriInfoRow(title: "Impuesto", value: profile.taxName, systemImage: "percent")
                AdminTaxSriInfoRow(title: "Tipo", value: profile.taxKind, systemImage: "square.stack.3d.up")
                AdminTaxSriInfoRow(title: "Tratamiento", value: profile.treatment, systemImage: "tag.circle")
                AdminTaxSriInfoRow(title: "Tarifa", value: profile.displayRate, systemImage: "chart.line.uptrend.xyaxis")
                AdminTaxSriInfoRow(title: "Origen", value: profile.source ?? "—", systemImage: "shippingbox")
            }

            Section("SRI") {
                AdminTaxSriInfoRow(title: "Código impuesto SRI", value: profile.sriTaxCode.isEmpty ? "—" : profile.sriTaxCode, systemImage: "doc.badge.gearshape")
                AdminTaxSriInfoRow(title: "Código tarifa SRI", value: profile.sriRateCode.isEmpty ? "—" : profile.sriRateCode, systemImage: "doc.badge.gearshape")
                AdminTaxSriInfoRow(title: "Facturable electrónicamente", value: profile.isElectronicallyBillable ? "Sí" : "No", systemImage: "checkmark.seal")
                AdminTaxSriInfoRow(title: "Base legal", value: profile.legalBasis ?? "—", systemImage: "building.columns")
                AdminTaxSriInfoRow(title: "Vigencia", value: "\(profile.effectiveFrom ?? "—") → \(profile.effectiveTo ?? "vigente")", systemImage: "calendar")
            }

            if profile.requiresEligibilityNotice {
                Section("Condiciones") {
                    AdminTaxSriInfoRow(title: "Elegibilidad turística", value: profile.requiresTourismEligibility ? "Requerida" : "No requerida", systemImage: "mountain.2")
                    AdminTaxSriInfoRow(title: "Código auxiliar construcción", value: profile.requiresConstructionMaterialAuxiliaryCode ? "Requerido" : "No requerido", systemImage: "hammer")
                    AdminTaxSriInfoRow(title: "Ventana vigente", value: profile.requiresActiveWindow ? "Requerida" : "No requerida", systemImage: "clock.badge.exclamationmark")
                    AdminTaxSriInfoRow(title: "Código de ventana", value: profile.eligibilityWindowCode ?? "—", systemImage: "calendar.badge.clock")
                }
            }
        }
        .navigationTitle(profile.name)
    }
}

private struct AdminTaxSriMiniBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.orange.opacity(0.14))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }
}
