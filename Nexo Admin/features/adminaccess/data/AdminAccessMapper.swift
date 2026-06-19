//
//  AdminAccessMapper.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import Foundation

extension AdminAccessUserDTO {
    func toDomain() -> AdminAccessUser {
        AdminAccessUser(
            id: id,
            email: email,
            displayName: displayName,
            phone: phone,
            status: status,
            membershipId: membershipId,
            membershipStatus: membershipStatus,
            roleIds: roleIds,
            roleNames: roleNames,
            effectivePermissions: effectivePermissions,
            activeSessionCount: activeSessionCount,
            invitedBy: invitedBy,
            acceptedAt: acceptedAt,
            blockedAt: blockedAt,
            blockedReason: blockedReason,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: version
        )
    }
}


extension AdminHumanCapabilityGroupDTO {
    func toDomain() -> AdminHumanCapabilityGroup {
        AdminHumanCapabilityGroup(
            code: code,
            title: title,
            description: description,
            humanBullets: humanBullets,
            permissionKeys: permissionKeys,
            requiredModules: requiredModules,
            sensitive: sensitive,
            rank: rank
        )
    }
}

extension AdminRoleDTO {
    func toDomain() -> AdminAccessRole {
        AdminAccessRole(
            id: id,
            code: code,
            organizationId: organizationId,
            scope: scope,
            type: type,
            name: name,
            description: description,
            permissionKeys: permissionKeys,
            systemRole: systemRole,
            critical: critical,
            editable: editable,
            status: status,
            schemaVersion: schemaVersion
        )
    }
}

extension AdminPermissionDTO {
    func toDomain() -> AdminAccessPermission {
        AdminAccessPermission(
            code: code,
            name: name,
            description: description,
            category: category,
            scope: scope,
            riskLevel: riskLevel,
            status: status,
            systemManaged: systemManaged,
            requiresAudit: requiresAudit,
            requiresReason: requiresReason,
            requiresStepUp: requiresStepUp,
            featureFlag: featureFlag
        )
    }
}

extension AdminInvitationDTO {
    func toDomain() -> AdminAccessInvitation {
        AdminAccessInvitation(
            id: id,
            organizationId: organizationId,
            email: email,
            invitedByUserId: invitedByUserId,
            roleIds: roleIds,
            roleNames: roleNames,
            status: status,
            createdAt: createdAt,
            expiresAt: expiresAt,
            acceptedAt: acceptedAt,
            revokedAt: revokedAt,
            acceptedUserId: acceptedUserId,
            version: version
        )
    }
}

extension AdminTemporaryUserResponseDTO {
    func toDomain() -> AdminTemporaryUserResult {
        AdminTemporaryUserResult(
            user: user.toDomain(),
            credentialId: credentialId,
            membershipId: membershipId,
            temporaryPassword: temporaryPassword,
            mustChangePassword: mustChangePassword,
            createdAt: createdAt
        )
    }
}

extension AdminInvitationCreatedResponseDTO {
    func toDomain() -> AdminInvitationCreatedResult {
        AdminInvitationCreatedResult(
            invitation: invitation.toDomain(),
            user: user.toDomain(),
            membershipId: membershipId,
            rawInvitationToken: rawInvitationToken,
            invitationUrl: invitationUrl,
            createdAt: createdAt
        )
    }
}

extension AdminInvitationResendResponseDTO {
    func toDomain() -> AdminInvitationResendResult {
        AdminInvitationResendResult(
            invitation: invitation.toDomain(),
            rawInvitationToken: rawInvitationToken,
            invitationUrl: invitationUrl
        )
    }
}

extension AdminResetUserPasswordResponseDTO {
    func toDomain() -> AdminResetPasswordResult {
        AdminResetPasswordResult(
            userId: userId,
            credentialId: credentialId,
            temporaryPassword: temporaryPassword,
            mustChangePassword: mustChangePassword,
            revokedSessions: revokedSessions,
            revokedRefreshTokens: revokedRefreshTokens,
            changedAt: changedAt
        )
    }
}

extension AdminUserSessionRevocationResponseDTO {
    func toDomain() -> AdminUserSessionRevocationResult {
        AdminUserSessionRevocationResult(
            userId: userId,
            revokedSessions: revokedSessions,
            revokedRefreshTokens: revokedRefreshTokens,
            revokedAt: revokedAt,
            reason: reason
        )
    }
}

extension CreateTemporaryAdminUserInput {
    func toRequest() -> CreateTemporaryAdminUserRequestDTO {
        CreateTemporaryAdminUserRequestDTO(
            email: email.trimmed,
            displayName: displayName.trimmed,
            roleIds: roleIds,
            temporaryPassword: temporaryPassword.trimmedOptional,
            phone: phone.trimmedOptional,
            reason: reason.trimmedOrDefault("Crear usuario temporal desde Nexo Admin iOS")
        )
    }
}

extension UpdateAdminUserInput {
    func toRequest() -> UpdateAdminUserRequestDTO {
        UpdateAdminUserRequestDTO(
            displayName: displayName.trimmedOptional,
            phone: clearPhone ? nil : phone.trimmedOptional,
            clearPhone: clearPhone,
            roleIds: roleIds.isEmpty ? nil : roleIds,
            reason: reason.trimmedOrDefault("Actualizar usuario desde Nexo Admin iOS")
        )
    }
}

extension CreateAdminInvitationInput {
    func toRequest() -> CreateAdminInvitationRequestDTO {
        CreateAdminInvitationRequestDTO(
            email: email.trimmed,
            displayName: displayName.trimmed,
            roleIds: roleIds,
            reason: reason.trimmedOrDefault("Crear invitación desde Nexo Admin iOS")
        )
    }
}

extension CreateAdminRoleInput {
    func toRequest() -> CreateAdminRoleRequestDTO {
        CreateAdminRoleRequestDTO(
            code: code.trimmed,
            name: name.trimmed,
            description: description.trimmed,
            permissionKeys: permissionKeys,
            reason: reason.trimmedOrDefault("Crear rol desde Nexo Admin iOS")
        )
    }
}

extension UpdateAdminRoleInput {
    func toRequest() -> UpdateAdminRoleRequestDTO {
        UpdateAdminRoleRequestDTO(
            name: name.trimmedOptional,
            description: description.trimmedOptional,
            permissionKeys: permissionKeys.isEmpty ? nil : permissionKeys,
            reason: reason.trimmedOrDefault("Actualizar rol desde Nexo Admin iOS")
        )
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    var trimmedOptional: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }

    func trimmedOrDefault(_ fallback: String) -> String {
        let value = trimmed
        return value.isEmpty ? fallback : value
    }
}
