//
//  LoadableViewState.swift
//  Nexo Admin
//
//  Created by José Ruiz on 20/5/26.
//

import Foundation

enum LoadableViewState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty(String)
    case failed(String)
}
