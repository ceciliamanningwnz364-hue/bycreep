import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(\.modelContext) private var context

    @Bindable var profile: UserProfile

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var allEntries: [FoodEntry]

    @Query(sort: \WaterLog.createdAt, order: .reverse)
    private var waterLogs: [WaterLog]

    @State private var selectedDate = Date()
    @State private var showingAddFood = false
    @State private var addMeal: MealType = .breakfast

    private var plan: NutritionPlan {
        NutritionCalculator.plan(for: profile)
    }

    private var dayEntries: [FoodEntry] {
        allEntries
            .filter { WeekClock.isSameDay($0.date, selectedDate) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var totals: NutritionTotals {
        NutritionTotals(entries: dayEntries)
    }

    private var dayWaterLogs: [WaterLog] {
        waterLogs.filter { WeekClock.isSameDay($0.date, selectedDate) }
    }

    private var waterTotal: Int {
        dayWaterLogs.reduce(0) { $0 + $1.milliliters }
    }

    private var remainingCalories: Double {
        plan.calories - totals.calories
    }

    private var isOver: Bool { remainingCalories < 0 }

    private var canGoForward: Bool {
        WeekClock.startOfDay(selectedDate) < WeekClock.startOfDay(Date())
    }

    private var isToday: Bool {
        WeekClock.isSameDay(selectedDate, Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                dateBar
                summaryCard
                quickActions
                waterCard

                ForEach(MealType.allCases) { meal in
                    mealCard(meal)
                }

                planFootnote
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAddFood) {
            AddFoodView(date: selectedDate, meal: addMeal)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ScreenTitle(eyebrow: "04 · Топливо", title: "Питание")

            Spacer(minLength: 8)

            Button {
                openAdd(suggestedMeal)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Добавить еду")
        }
    }

    private var dateBar: some View {
        HStack(spacing: 10) {
            dayButton(systemName: "chevron.left", enabled: true) {
                shiftDay(-1)
            }

            Button {
                selectedDate = Date()
                Haptics.tap()
            } label: {
                VStack(spacing: 2) {
                    Text(dateTitle.uppercased())
                        .font(ByFont.label)
                        .tracking(1)
                        .foregroundStyle(isToday ? Theme.red : Theme.text)
                    Text(Formatters.fullDate(selectedDate))
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Вернуться к сегодня")

            dayButton(systemName: "chevron.right", enabled: canGoForward) {
                shiftDay(1)
            }
        }
        .byCard(padding: 12, radius: 18)
    }

    private func dayButton(
        systemName: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(enabled ? Theme.text : Theme.tertiary)
                .frame(width: 38, height: 38)
                .background(Theme.surfaceSoft, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemName == "chevron.left" ? "Предыдущий день" : "Следующий день")
    }

    // MARK: Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(isToday ? "СЕГОДНЯ" : "ДЕНЬ")
                    .font(ByFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondary)

                Spacer()

                Text(profile.goal.title.uppercased())
                    .font(ByFont.micro)
                    .tracking(0.6)
                    .foregroundStyle(Theme.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.redSoft, in: Capsule())
            }

            HStack(spacing: 18) {
                ActivityRing(
                    progress: plan.calories > 0 ? totals.calories / plan.calories : 0,
                    value: Formatters.integer(abs(remainingCalories)),
                    caption: isOver ? "ккал сверху" : "ккал осталось",
                    size: 116,
                    lineWidth: 10
                )

                VStack(spacing: 12) {
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

    private var quickActions: some View {
        HStack(spacing: 9) {
            Button {
                openAdd(suggestedMeal)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .black))
                    Text("ДОБАВИТЬ ЕДУ")
                        .font(ByFont.micro)
                        .tracking(0.6)
                }
            }
            .buttonStyle(GhostButtonStyle())

            Button {
                addWater(250)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("+250 МЛ")
                        .font(ByFont.micro)
                        .tracking(0.6)
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    // MARK: Water

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text("ВОДА")
                    .font(ByFont.label)
                    .tracking(1.1)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("\(waterTotal) / \(Int(plan.waterML)) мл")
                    .font(ByFont.mono(10, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.45)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: waterWidth(proxy.size.width))
                }
            }
            .frame(height: 7)
            .clipShape(Capsule())

            HStack(spacing: 10) {
                Button {
                    removeLastWater()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(dayWaterLogs.isEmpty ? Theme.tertiary : Theme.text)
                        .frame(width: 34, height: 34)
                        .background(Theme.surfaceSoft, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(dayWaterLogs.isEmpty)
                .accessibilityLabel("Убрать 250 мл воды")

                Button {
                    addWater(250)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .black))
                        Text("250 МЛ")
                            .font(ByFont.micro)
                            .tracking(0.5)
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Theme.red.opacity(0.16), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(waterHint)
                    .font(ByFont.regular(10.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
            }
        }
        .byCard()
    }

    private func waterWidth(_ fullWidth: CGFloat) -> CGFloat {
        guard plan.waterML > 0 else { return 0 }
        let ratio = min(max(Double(waterTotal) / plan.waterML, 0), 1)
        return fullWidth * ratio
    }

    private var waterHint: String {
        if waterTotal <= 0 { return "Начни с одного стакана" }
        if Double(waterTotal) >= plan.waterML { return "Норма закрыта" }
        return "Осталось \(Int(plan.waterML) - waterTotal) мл"
    }

    // MARK: Meals

    private func mealCard(_ meal: MealType) -> some View {
        let entries = dayEntries.filter { $0.meal == meal }
        let calories = entries.reduce(0) { $0 + $1.calories }

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(entries.isEmpty ? Theme.surfaceSoft : Theme.redSoft)
                        .frame(width: 38, height: 38)
                    Image(systemName: meal.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(entries.isEmpty ? Theme.tertiary : Theme.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(meal.title)
                        .font(ByFont.heavy(15))
                        .foregroundStyle(Theme.text)
                    Text(entries.isEmpty
                         ? "Ничего не добавлено"
                         : "\(entries.count) · \(Formatters.kcal(calories))")
                        .font(ByFont.regular(10.5))
                        .foregroundStyle(Theme.tertiary)
                }

                Spacer(minLength: 6)

                Button {
                    openAdd(meal)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Theme.text)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Добавить в \(meal.title.lowercased())")
            }
            .padding(14)

            if !entries.isEmpty {
                ByDivider()
                    .padding(.horizontal, 14)

                ForEach(entries, id: \.id) { entry in
                    entryRow(entry)
                    if entry.id != entries.last?.id {
                        ByDivider()
                            .padding(.leading, 14)
                    }
                }
            }
        }
        .byCard(padding: 0)
    }

    private func entryRow(_ entry: FoodEntry) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(ByFont.semibold(13))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    if let grams = entry.grams, grams > 0 {
                        Text(Formatters.grams(grams))
                        Text("·")
                    }
                    Text("Б \(Formatters.integer(entry.protein))")
                    Text("У \(Formatters.integer(entry.carbs))")
                    Text("Ж \(Formatters.integer(entry.fat))")
                }
                .font(ByFont.regular(9.5))
                .foregroundStyle(Theme.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 6)

            Text(Formatters.integer(entry.calories))
                .font(ByFont.mono(12, weight: .semibold))
                .foregroundStyle(Theme.text)
                .monospacedDigit()

            Menu {
                Button(role: .destructive) {
                    delete(entry)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 26, height: 34)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var planFootnote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Цель: \(Formatters.kcal(plan.calories)) · Б \(Formatters.integer(plan.protein)) / У \(Formatters.integer(plan.carbs)) / Ж \(Formatters.integer(plan.fat))")
                .font(ByFont.mono(10, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("Норма рассчитана по полу, возрасту, весу и активности из профиля. Поправь параметры — цель пересчитается сама.")
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 4)
    }

    // MARK: Helpers

    private var dateTitle: String {
        if isToday { return "Сегодня" }
        let yesterday = WeekClock.calendar.date(
            byAdding: .day,
            value: -1,
            to: WeekClock.startOfDay(Date())
        )
        if let yesterday, WeekClock.isSameDay(selectedDate, yesterday) {
            return "Вчера"
        }
        return Formatters.weekdayFull(WeekClock.weekdayIndex(for: selectedDate))
    }

    private var suggestedMeal: MealType {
        let hour = WeekClock.calendar.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<21: return .dinner
        default: return .snack
        }
    }

    private func shiftDay(_ delta: Int) {
        guard let date = WeekClock.calendar.date(byAdding: .day, value: delta, to: selectedDate) else {
            return
        }
        if delta > 0, WeekClock.startOfDay(date) > WeekClock.startOfDay(Date()) {
            return
        }
        selectedDate = date
        Haptics.tap()
    }

    private func openAdd(_ meal: MealType) {
        addMeal = meal
        showingAddFood = true
        Haptics.tap()
    }

    private func delete(_ entry: FoodEntry) {
        context.delete(entry)
        ProgramStore.save(context)
        Haptics.warning()
    }

    private func addWater(_ amount: Int) {
        let log = WaterLog(date: selectedDate, milliliters: amount)
        context.insert(log)
        ProgramStore.save(context)
        Haptics.tap()
    }

    private func removeLastWater() {
        guard let last = dayWaterLogs.first else { return }
        context.delete(last)
        ProgramStore.save(context)
        Haptics.warning()
    }
}
