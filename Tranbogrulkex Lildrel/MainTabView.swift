import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Play")
                }

            CreateView()
                .tabItem {
                    Image(systemName: "pencil.and.outline")
                    Text("Create")
                }

            ExploreView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Explore")
                }
        }
        .tint(.appPrimary)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

