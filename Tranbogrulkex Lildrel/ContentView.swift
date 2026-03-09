//
//  ContentView.swift
//  Tranbogrulkex Lildrel
//
//  Created by Роман Главацкий on 09.03.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appData = AppData()

    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()

            Group {
                if appData.hasSeenOnboarding {
                    MainTabView()
                        .environmentObject(appData)
                } else {
                    OnboardingContainerView {
                        appData.markOnboardingSeen()
                    }
                    .environmentObject(appData)
                }
            }
        }
    }
}

