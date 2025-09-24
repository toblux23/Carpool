//
//  Briones_CarpoolApp.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/2/25.
//

import SwiftUI

import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct Briones_CarpoolApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authVM = AuthViewModel()
    var body: some Scene {
        WindowGroup {
            if authVM.isAuthenticated {
                ContentView()
                    .environmentObject(authVM)
            } else {
                AuthContainerView()
                    .environmentObject(authVM)
            }
        }
        .modelContainer(for: [UserProfile.self])

    }
}
