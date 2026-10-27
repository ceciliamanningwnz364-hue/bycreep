import SwiftUI
import SwiftData
import UIKit

@main
struct BycreepApp: App {
    private let container: ModelContainer

    init() {
        Self.configureAppearance()

        let schema = Schema([
            UserProfile.self,
            Program.self,
            ProgramDay.self,
            ProgramExercise.self,
            WorkoutSession.self,
            SessionExercise.self,
            SetEntry.self,
            ProgressPhoto.self,
            BodyMeasurement.self,
            FoodEntry.self,
            WaterLog.self
        ])

        do {
            let configuration = ModelConfiguration(
                "bycreep",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("bycreep: could not create SwiftData container — \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .tint(Theme.red)
        }
    }

    private static func configureAppearance() {
        let background = UIColor(hex: 0x070708)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = background
        tabAppearance.shadowColor = UIColor.clear

        let normalColor = UIColor.white.withAlphaComponent(0.42)
        let selectedColor = UIColor.white

        let item = tabAppearance.stackedLayoutAppearance
        item.normal.iconColor = normalColor
        item.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        item.selected.iconColor = selectedColor
        item.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = background
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
