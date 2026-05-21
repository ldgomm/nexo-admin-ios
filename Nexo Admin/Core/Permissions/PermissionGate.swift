//
//  PermissionGate.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import SwiftUI

struct PermissionGate<Content: View, Fallback: View>: View {
    let permissions: Set<String>
    let required: Set<String>
    @ViewBuilder let content: () -> Content
    @ViewBuilder let fallback: () -> Fallback

    var body: some View {
        if PermissionSet(values: permissions).canAny(required) {
            content()
        } else {
            fallback()
        }
    }
}

extension PermissionGate where Fallback == EmptyView {
    init(
        permissions: Set<String>,
        required: Set<String>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.permissions = permissions
        self.required = required
        self.content = content
        self.fallback = { EmptyView() }
    }
}
