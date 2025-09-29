//
//  rootView.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/24/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.isAuthenticated {
                // Show your landing screen
                ContentView()
            } else if !authVM.isProfileCompleted {
                // Show profile setup after login/signup
                MultiStepProfileSetupView {
                    authVM.isProfileCompleted = true
                }
            } else {
                MainContainerView()
            }
        }
    }
}
