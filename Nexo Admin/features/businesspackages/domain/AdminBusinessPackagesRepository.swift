//
//  AdminBusinessPackagesRepository.swift
//  Nexo Admin
//
//  Created by José Ruiz on 22/6/26.
//

import Foundation

protocol AdminBusinessPackagesRepository: Sendable {
    func loadBusinessPackages() async throws -> AdminBusinessPackageCatalogResponse
}
