import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]

    @State private var selection = 0

    var body: some View {
        ZStack {
            ByBackground()

            if let profile = profiles.first {
                MainTabs(profile: profile, selection: $selection)
            } else {
                OnboardingView()
            }
        }
        .task {
            WidgetBridge.refresh(context: context)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetBridge.refresh(context: context)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "bycreep" else { return }
            selection = 0
        }
    }
}

struct MainTabs: View {
    @Bindable var profile: UserProfile
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                TodayView(profile: profile, selection: $selection)
            }
            .tabItem {
                Label("Сегодня", systemImage: "bolt.fill")
            }
            .tag(0)

            NavigationStack {
                ProgramsView(profile: profile)
            }
            .tabItem {
                Label("Зал", systemImage: "dumbbell.fill")
            }
            .tag(1)

            NavigationStack {
                ProgressScreen(profile: profile)
            }
            .tabItem {
                Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)

            NavigationStack {
                NutritionView(profile: profile)
            }
            .tabItem {
                Label("Питание", systemImage: "fork.knife")
            }
            .tag(3)

            NavigationStack {
                ProfileView(profile: profile)
            }
            .tabItem {
                Label("Профиль", systemImage: "person.fill")
            }
            .tag(4)
        }
        .toolbarBackground(Theme.bg, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
