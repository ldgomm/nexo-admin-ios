//
//  URL+NexoPath.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

extension URL {
    func appendingNexoPath(_ path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(self) { partial, component in
                partial.appendingPathComponent(String(component))
            }
    }
}
