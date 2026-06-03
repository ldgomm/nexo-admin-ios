import Combine
import Foundation

@MainActor
final class AdminOrganizationAccessViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(AdminOrganizationModuleSettings)
        case failed(String)
    }

    private let organizationId: String
    private let repository: AdminOrganizationAccessRepository

    @Published var state: State = .idle
    @Published var businessType = "restaurant"
    @Published var enabledModules: Set<String> = []
    @Published var disabledModules: Set<String> = []
    @Published var reason = ""
    @Published var superAdminEmail = ""
    @Published var superAdminName = ""
    @Published var superAdminPhone = ""
    @Published var temporaryPassword: String?

    init(organizationId: String, repository: AdminOrganizationAccessRepository) {
        self.organizationId = organizationId
        self.repository = repository
    }

    func load() async {
        state = .loading
        do {
            let settings = try await repository.getModuleSettings(organizationId: organizationId)
            businessType = settings.businessType
            enabledModules = settings.enabledModules
            disabledModules = settings.disabledModules
            state = .loaded(settings)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func saveModules() async {
        state = .loading
        do {
            let input = AdminUpdateOrganizationModulesInput(
                businessType: businessType,
                enabledModules: enabledModules,
                disabledModules: disabledModules,
                reason: reason
            )
            state = .loaded(try await repository.updateModuleSettings(organizationId: organizationId, input: input))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func createSuperAdmin() async {
        do {
            let result = try await repository.createSuperAdmin(
                organizationId: organizationId,
                input: AdminCreateOrganizationSuperAdminInput(
                    email: superAdminEmail,
                    displayName: superAdminName,
                    phone: superAdminPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : superAdminPhone,
                    temporaryPassword: nil,
                    reason: reason
                )
            )
            temporaryPassword = result.temporaryPassword
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
