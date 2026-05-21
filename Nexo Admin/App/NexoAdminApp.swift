//
//  NexoAdminApp.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

@main
struct NexoAdminApp: App {
    @StateObject private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .task {
                    await container.authCoordinator.restoreSession()
                }
        }
    }
}
