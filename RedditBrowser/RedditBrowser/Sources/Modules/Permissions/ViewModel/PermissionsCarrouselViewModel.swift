//
//  PermissionsCarrouselViewModel.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 24/04/23.
//

import Foundation
import Combine

class PermissionsCarrouselViewModel {
    struct Input {
        let viewDidLoadPublisher: AnyPublisher<Void, Never>
        let allowButtonTappedPublisher: AnyPublisher<Void, Never>
        let cancelButtonTappedPublisher: AnyPublisher<Void, Never>
    }

    struct Output {
        let setViewTypePublisher: AnyPublisher<PermissionViewType, Never>
        let allowButtonTappedPublisher: AnyPublisher<Void, Never>
        let cancelButtonTappedPublisher: AnyPublisher<Void, Never>
        let changeViewTypePublisher: AnyPublisher<PermissionViewType?, Never>
    }

    private var permissions: PermissionManager
    @Published var type: PermissionViewType? = .requestCamera

    init(permissions: PermissionManager = PermissionManager()){
        self.permissions = permissions
    }

    func transform(input: Input) -> Output {
        let setViewTypePublisher: AnyPublisher<PermissionViewType, Never> = input.viewDidLoadPublisher
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadViewTypeToNextPermission()
            }).flatMap { [unowned self] _ in
                return Just(type ?? .requestCamera).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        let allowButtonTappedPublisher: AnyPublisher<Void, Never> = input.allowButtonTappedPublisher
            .handleEvents(receiveOutput: { [unowned self] _ in
                let type = type ?? .requestCamera
                permissions.request(for: type.permissionType) { status in
                    let type = self.type ?? .requestCamera
                    self.type = PermissionViewType(rawValue: type.permissionType.rawValue + 1)
                }
            }).flatMap { _ in
                return Just(()).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        let cancelButtonTappedPublisher: AnyPublisher<Void, Never> =  input.cancelButtonTappedPublisher
            .handleEvents(receiveOutput: { [unowned self] _ in
                let type = self.type ?? .requestCamera
                self.type = PermissionViewType(rawValue: type.permissionType.rawValue + 1)
            }).flatMap { _ in
                return Just(()).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        let changeViewTypePublisher: AnyPublisher<PermissionViewType?, Never> = $type
            .handleEvents(receiveOutput: { [weak self] viewType in
                if viewType == nil {
                    self?.setDidFinishPermissionFlow()
                }
            }).flatMap { viewType in
                return Just(viewType).eraseToAnyPublisher()
            }.eraseToAnyPublisher()

        return .init(setViewTypePublisher: setViewTypePublisher,
                     allowButtonTappedPublisher: allowButtonTappedPublisher,
                     cancelButtonTappedPublisher: cancelButtonTappedPublisher,
                     changeViewTypePublisher: changeViewTypePublisher)
    }

    private func loadViewTypeToNextPermission() {
        guard let permissionRawValue = permissions.checkLastPermission()?.rawValue,
              let type = PermissionViewType(rawValue: permissionRawValue) else {
            setDidFinishPermissionFlow()
            return
        }
        self.type = type
    }

    private func setDidFinishPermissionFlow() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.didFinishPermissionFlow.rawValue)
    }
}
