//
//  AppDelegate.swift
//  App
//
//  Created by joker on 2025-03-08.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken token: Data
    ) {
        print("Token: \(token.map { String(format: "%02x", $0) }.joined())")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("\(error.localizedDescription)")
    }
}
