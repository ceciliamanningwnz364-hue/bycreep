import SwiftUI
import SwiftData

struct NutritionTodayCard: View {
    let profile: UserProfile
    var onOpen: () -> Void

    @Query private var entries: [FoodEntry]

    init(profile: UserProfile, onOpen: @escaping () -> Void) {
        self.profile = profile
        self.onOpen = onOpen

        let calendar = WeekClock.calendar
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start)
            ?? start.addingTimeInterval(86_400)

        _entries = Query(
            filter: #Predicate<FoodEntry> { entry in
                entry.date >= start && entry.date < end
            },
            sort: \FoodEntry.createdAt
        )
    }

    private var plan: NutritionPlan {
        NutritionCalculator.plan(for: profile)
    }

    private var totals: NutritionTotals {
        NutritionTotals(entries: entries)
    }

    private var remaining: Double {
        plan.calories - totals.calories
    }

    private var isOver: Bool { remaining < 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Питание", actionTitle: "Открыть", action: onOpen)

            HStack(spacing: 20) {
                ActivityRing(
                    progress: plan.calories > 0 ? totals.calories / plan.calories : 0,
                    value: Formatters.integer(abs(remaining)),
                    caption: isOver ? "ккал сверху" : "ккал осталось",
                    size: 112,
                    lineWidth: 9
                )

                VStack(spacing: 13) {
                    MacroBarView(
                        title: "Белки",
                        current: totals.protein,
                        goal: plan.protein,
                        tint: Theme.red
                    )
                    MacroBarView(
                        title: "Углеводы",
                        current: totals.carbs,
                        goal: plan.carbs,
                        tint: Theme.text
                    )
                    MacroBarView(
                        title: "Жиры",
                        current: totals.fat,
                        goal: plan.fat,
                        tint: Color.white.opacity(0.38)
                    )
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 5) {
                Text("Съедено")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                Text(Formatters.kcal(totals.calories))
                    .font(ByFont.mono(11, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Text("· цель")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                Text(Formatters.kcal(plan.calories))
                    .font(ByFont.mono(11, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Spacer(minLength: 0)
            }
        }
        .byCard()
    }
}
