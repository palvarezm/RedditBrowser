//
//  PermissionManager.swift
//  RedditBrowser
//
//  Created by Paul Alvarez on 23/04/23.
//

import Foundation
import AVFoundation
import UserNotifications
import CoreLocation

enum PermissionType: Int {
    case camera
    case notifications
    case location
}

enum PermissionStatus: Int {
    case unknown
    case denied
    case granted
}

class PermissionManager: NSObject {
    // MARK: - Properties
    lazy var notificationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
    private var _locationManager: CLLocationManager?
    private var locationCompletion: ((PermissionStatus) -> Void)?
    var locationManager: CLLocationManager {
        if _locationManager == nil {
            _locationManager = CLLocationManager()
            _locationManager?.delegate = self
        }
        return _locationManager!
    }
    
    // MARK: - Getters
    subscript(type: PermissionType) -> PermissionStatus {
        get {
            return self.status(for: type)
        }
    }

    func status(`for` type: PermissionType) -> PermissionStatus {
        let status: PermissionStatus

        switch type {
        case .camera:
            status = self.cameraStatus
        case .notifications:
            status = self.notificationsStatus
        case .location:
            status = self.locationStatus
            break
        }
        return status
    }

    private var cameraStatus: PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unknown
        default:
            return .unknown
        }
    }

    private var notificationsStatus: PermissionStatus {
        var notificationStatus: UNAuthorizationStatus?
        let semaphore = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getNotificationSettings() { settings in
            notificationStatus = settings.authorizationStatus
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
        
        return PermissionStatus(rawValue: notificationStatus!.rawValue)!
    }

    private var locationStatus: PermissionStatus {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            return .unknown
        case .restricted, .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            return .granted
        default:
            return .unknown
        }
    }

    // MARK: - Requests
    func request(`for` type: PermissionType, completion: @escaping (PermissionStatus) -> Void) {
        func callback(_ granted: Bool) {
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }

        switch type {
        case .camera:
            self.requestCameraAccess(callback)
        case .notifications:
            self.requestNotificationsAccess(callback)
        case .location:
            locationCompletion = completion
            self.requestLocationAccess(callback)
        }
    }

    private func requestCameraAccess(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }

    private func requestNotificationsAccess(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: self.notificationOptions) { granted, _ in
            completion(granted)
        }
    }

    private func requestLocationAccess(_ completion: @escaping(Bool) -> Void) {
        self.locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - CheckPermissions
    func checkLastPermission() -> PermissionType? {
        if self[.location] != .unknown {
            return nil
        } else if self[.notifications] != .unknown {
            return .location
        } else if self[.camera] != .unknown {
            return .notifications
        } else {
            return .camera
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension PermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationCompletion?(locationStatus)
    }
}
