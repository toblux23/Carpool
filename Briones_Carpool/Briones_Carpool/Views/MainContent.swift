//
//  main.swift
//  Briones_Carpool
//
//  Created by STUDENT on 9/18/25.
//

import SwiftUI
import FirebaseAuth
struct MainContainerView: View {
    enum Tab {
        case home, dashboard, notifications
    }

    @State private var selectedTab: Tab = .home

    var body: some View {
        
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .dashboard:
                    DashboardView()
                case .notifications:
                    NotificationView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Spacer()
                Button(action: { selectedTab = .home }) {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                }
                Spacer()
                Button(action: { selectedTab = .dashboard }) {
                    Image(systemName: selectedTab == .dashboard ? "car.fill" : "car")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                }
                Spacer()
                Button(action: { selectedTab = .notifications }) {
                    Image(systemName: selectedTab == .notifications ? "bell.fill" : "bell")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(red: 128/255, green: 0, blue: 0))
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color.white.shadow(radius: 2))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview{
    MainContainerView()
}

