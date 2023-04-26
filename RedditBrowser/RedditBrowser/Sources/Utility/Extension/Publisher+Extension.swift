//
//  Publisher+Extension.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 25/04/23.
//

import Combine

extension Publisher {
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Self.Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>> where T.Failure == Self.Failure {
        map(transform).switchToLatest()
    }
}
