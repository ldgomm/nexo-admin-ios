//
//  NexoAdminApp.swift
//  Nexo Admin
//
//  Created by José Ruiz on 21/5/26.
//

import SwiftUI

@main
struct NexoAdminApp: App {
    @StateObject private var container = AppContainer.live(environment: .current())

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .task {
                    await container.authCoordinator.restoreSession()
                }
        }
    }
}
