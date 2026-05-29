//
//  AdminTaxProfilesView.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

struct AdminTaxProfilesView: View {
    @ObservedObject var viewModel: AdminTaxSriViewModel

    var body: some View {
        AdminTaxSriSectionCard(title: "Perfiles tributarios", subtitle: "Tarifas y códigos SRI consumidos desde backend", systemImage: "list.bullet.rectangle") {
            if viewModel.taxProfiles.isEmpty {
                Text("No hay perfiles tributarios disponibles.").foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.taxProfiles) { profile in
                    NavigationLink {
                        AdminTaxProfileDetailView(profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name).font(.subheadline.weight(.semibold))
                                Text("\(profile.taxName) \(NSDecimalNumber(decimal: profile.rate).stringValue)% • SRI \(profile.sriTaxCode)/\(profile.sriRateCode)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            AdminTaxSriStatusBadge(text: profile.status)
                        }
                        .contentShape(Rectangle())
                    }
                    Divider()
                }
            }
        }
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
            }
            Section("SRI") {
                AdminTaxSriInfoRow(title: "Impuesto", value: profile.taxName, systemImage: "percent")
                AdminTaxSriInfoRow(title: "Tarifa", value: "\(NSDecimalNumber(decimal: profile.rate).stringValue)%", systemImage: "chart.line.uptrend.xyaxis")
                AdminTaxSriInfoRow(title: "Código impuesto SRI", value: profile.sriTaxCode, systemImage: "doc.badge.gearshape")
                AdminTaxSriInfoRow(title: "Código tarifa SRI", value: profile.sriRateCode, systemImage: "doc.badge.gearshape")
                AdminTaxSriInfoRow(title: "Base legal", value: profile.legalBasis ?? "—", systemImage: "building.columns")
                AdminTaxSriInfoRow(title: "Vigencia", value: "\(profile.effectiveFrom ?? "—") → \(profile.effectiveTo ?? "vigente")", systemImage: "calendar")
            }
        }
        .navigationTitle(profile.name)
    }
}
