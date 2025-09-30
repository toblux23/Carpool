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
                ContentView()
            } else if !authVM.isProfileCompleted {
                MultiStepProfileSetupView {
                    authVM.isProfileCompleted = true
                }
            } else {
                MainContainerView()
            }
        }
    }
}
