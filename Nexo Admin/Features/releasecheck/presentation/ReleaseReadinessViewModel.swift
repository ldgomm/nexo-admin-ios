//
//  ReleaseReadinessViewModel.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Combine
import Foundation

@MainActor
final class ReleaseReadinessViewModel: ObservableObject {
    @Published private(set) var report: ReleaseReadinessReport?

    private let sessionStore: AuthSessionStore
    private let buildInfoProvider: () -> BuildInfo
    private let now: () -> Date

    init(
        sessionStore: AuthSessionStore,
        buildInfoProvider: @escaping () -> BuildInfo = { BuildInfo.current() },
        now: @escaping () -> Date = Date.init
    ) {
        self.sessionStore = sessionStore
        self.buildInfoProvider = buildInfoProvider
        self.now = now
    }

    func load() {
        let buildInfo = buildInfoProvider()
        report = ReleaseReadinessReport(
            generatedAt: now(),
            buildInfo: buildInfo,
            sections: [
                buildSection(buildInfo),
                sessionSection(),
                permissionsSection(),
                securitySection(),
                uxSection(),
                sriBoundarySection(),
                testFlightSection(buildInfo)
            ]
        )
    }

    private func buildSection(_ buildInfo: BuildInfo) -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "build",
            title: "Build",
            checks: [
                ReleaseReadinessCheck(
                    id: "build.version",
                    title: "Versión configurada",
                    detail: buildInfo.displayVersion,
                    status: buildInfo.version == "0.0.0" || buildInfo.build == "0" ? .warning : .passed,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "build.bundle",
                    title: "Bundle identifier",
                    detail: buildInfo.bundleIdentifier,
                    status: buildInfo.bundleIdentifier == "unknown.bundle" ? .warning : .passed,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "build.api",
                    title: "Base URL de API",
                    detail: buildInfo.apiBaseURL,
                    status: buildInfo.isLocalAPI ? .failed : .passed,
                    required: true
                )
            ]
        )
    }

    private func sessionSection() -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "session",
            title: "Sesión y organización",
            checks: [
                ReleaseReadinessCheck(
                    id: "session.phase",
                    title: "Sesión autenticada",
                    detail: sessionStore.phase == .authenticated ? "La sesión activa entró al shell principal." : "La sesión actual no está autenticada.",
                    status: sessionStore.phase == .authenticated ? .passed : .warning,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "session.organization",
                    title: "Organización activa",
                    detail: sessionStore.activeOrganization?.commercialName ?? sessionStore.activeOrganization?.legalName ?? "Sin organización activa en memoria.",
                    status: sessionStore.activeOrganization == nil ? .warning : .passed,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "session.user",
                    title: "Usuario actual",
                    detail: sessionStore.currentUser?.email ?? "Sin usuario actual en memoria.",
                    status: sessionStore.currentUser == nil ? .warning : .passed,
                    required: false
                )
            ]
        )
    }

    private func permissionsSection() -> ReleaseReadinessSection {
        let permissions = PermissionSet(sessionStore.effectivePermissions)
        let criticalPermissions = [
            PermissionCatalog.reportsDashboardView,
            PermissionCatalog.credentialsUsersView,
            PermissionCatalog.catalogLocalView,
            PermissionCatalog.taxSettingsView,
            PermissionCatalog.documentsView,
            PermissionCatalog.auditView
        ]

        return ReleaseReadinessSection(
            id: "permissions",
            title: "Permisos",
            checks: [
                ReleaseReadinessCheck(
                    id: "permissions.loaded",
                    title: "Permisos efectivos cargados",
                    detail: "\(sessionStore.effectivePermissions.count) permisos efectivos en memoria.",
                    status: sessionStore.effectivePermissions.isEmpty ? .warning : .passed,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "permissions.mvp",
                    title: "Permisos MVP detectables",
                    detail: "Dashboard, usuarios, catálogo, fiscal/SRI, comprobantes y auditoría.",
                    status: permissions.can(PermissionCatalog.all) || criticalPermissions.allSatisfy({ permissions.can($0) }) ? .passed : .warning,
                    required: false
                )
            ]
        )
    }

    private func securitySection() -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "security",
            title: "Seguridad",
            checks: [
                ReleaseReadinessCheck(
                    id: "security.keychain",
                    title: "Tokens en Keychain",
                    detail: "El almacenamiento seguro se mantiene en KeychainAuthTokenStore.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "security.secrets",
                    title: "Secretos no persistidos en UI",
                    detail: "Contraseñas temporales y tokens de invitación se muestran solo como resultado inmediato.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "security.permissions",
                    title: "Acciones ocultas por permisos",
                    detail: "Las pantallas usan PermissionSet/PermissionGate y el backend sigue validando permisos.",
                    status: .manual,
                    required: true
                )
            ]
        )
    }

    private func uxSection() -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "ux",
            title: "UX operativo",
            checks: [
                ReleaseReadinessCheck(
                    id: "ux.loading",
                    title: "Estados loading/empty/error/retry",
                    detail: "Las pantallas críticas usan LoadableViewState, EmptyStateView y ErrorStateView.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "ux.refresh",
                    title: "Pull to refresh",
                    detail: "Dashboard, usuarios, negocio, catálogo, fiscal, comprobantes y reportes exponen refresh.",
                    status: .manual,
                    required: false
                ),
                ReleaseReadinessCheck(
                    id: "ux.critical.confirmations",
                    title: "Confirmaciones críticas",
                    detail: "Bloqueos, revocaciones, firma, producción SRI y acciones sensibles piden motivo o confirmación.",
                    status: .manual,
                    required: true
                )
            ]
        )
    }

    private func sriBoundarySection() -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "sri",
            title: "Frontera SRI",
            checks: [
                ReleaseReadinessCheck(
                    id: "sri.no-signing",
                    title: "Sin firma XML en iOS",
                    detail: "La app administra configuración y artefactos; el backend firma y envía al SRI.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "sri.no-tax-source",
                    title: "Sin cálculo tributario definitivo en iOS",
                    detail: "La app muestra settings/perfiles; el Tax Engine vive en backend.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "sri.production-gate",
                    title: "Gate de producción",
                    detail: "La habilitación de producción se solicita con confirmación fuerte y queda decidida por backend.",
                    status: .manual,
                    required: true
                )
            ]
        )
    }

    private func testFlightSection(_ buildInfo: BuildInfo) -> ReleaseReadinessSection {
        ReleaseReadinessSection(
            id: "testflight",
            title: "TestFlight interno",
            checks: [
                ReleaseReadinessCheck(
                    id: "testflight.api",
                    title: "API no local",
                    detail: buildInfo.isLocalAPI ? "Cambia NexoAPIBaseURL antes de subir." : "API apuntando a \(buildInfo.apiBaseURL).",
                    status: buildInfo.isLocalAPI ? .failed : .passed,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "testflight.scheme",
                    title: "Scheme compartido",
                    detail: "Verificar en Xcode: Product > Scheme > Manage Schemes > Shared.",
                    status: .manual,
                    required: true
                ),
                ReleaseReadinessCheck(
                    id: "testflight.archive",
                    title: "Archive reproducible",
                    detail: "Ejecutar script scripts/ios/testflight_smoke.sh antes de subir.",
                    status: .manual,
                    required: true
                )
            ]
        )
    }
}
