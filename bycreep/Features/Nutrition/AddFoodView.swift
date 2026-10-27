import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var meal: MealType
    @State private var mode = 0
    @State private var search = ""

    @State private var manualName = ""
    @State private var manualGrams = ""
    @State private var manualCalories = ""
    @State private var manualProtein = ""
    @State private var manualCarbs = ""
    @State private var manualFat = ""

    @FocusState private var focusedField: Field?

    private enum Field {
        case search, name, grams, calories, protein, carbs, fat
    }

    init(date: Date, meal: MealType) {
        self.date = date
        _meal = State(initialValue: meal)
    }

    private var filteredItems: [FoodItem] {
        FoodDatabase.search(search)
    }

    private var manualIsValid: Bool {
        !manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (decimalValue(manualCalories) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    mealPicker
                    SegmentBar(titles: ["База", "Вручную"], selection: $mode)

                    if mode == 0 {
                        databaseSection
                    } else {
                        manualSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if mode == 1 {
                    manualSaveButton
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 32, height: 32)
                            .background(Theme.surfaceElevated, in: Circle())
                    }
                    .accessibilityLabel("Закрыть")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        focusedField = nil
                    }
                    .foregroundStyle(Theme.text)
                }
            }
            .navigationDestination(for: FoodItem.self) { item in
                FoodPortionView(
                    food: item,
                    date: date,
                    meal: meal
                ) {
                    dismiss()
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("НОВЫЙ ПРИЁМ")
                .font(ByFont.label)
                .tracking(1.5)
                .foregroundStyle(Theme.red)
            Text("Добавить еду")
                .font(ByFont.display(32))
                .tracking(-0.9)
                .foregroundStyle(Theme.text)
            Text("\(Formatters.fullDate(date)) · \(meal.title.lowercased())")
                .font(ByFont.regular(12))
                .foregroundStyle(Theme.secondary)
        }
        .padding(.top, 4)
    }

    private var mealPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ПРИЁМ ПИЩИ")
                .font(ByFont.label)
                .tracking(1.1)
                .foregroundStyle(Theme.secondary)
            MealPickerRow(selection: $meal)
        }
    }

    // MARK: Database

    private var databaseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField

            if filteredItems.isEmpty {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "Ничего не найдено",
                    message: "Попробуй другое название или добавь продукт вручную.",
                    actionTitle: "Добавить вручную",
                    action: {
                        mode = 1
                        Haptics.tap()
                    }
                )
                .byCard()
            } else {
                ForEach(FoodCategory.allCases) { category in
                    let items = filteredItems.filter { $0.category == category }
                    if !items.isEmpty {
                        foodGroup(category: category, items: items)
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.tertiary)

            TextField("Найти продукт", text: $search)
                .font(ByFont.regular(14))
                .foregroundStyle(Theme.text)
                .focused($focusedField, equals: .search)
                .submitLabel(.search)
                .autocorrectionDisabled()

            if !search.isEmpty {
                Button {
                    search = ""
                    Haptics.tap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .byField(minHeight: 46)
    }

    private func foodGroup(category: FoodCategory, items: [FoodItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text(category.rawValue.uppercased())
                    .font(ByFont.label)
                    .tracking(1)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("\(items.count)")
                    .font(ByFont.mono(9, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        foodRow(item)
                    }
                    .buttonStyle(.plain)

                    if item.id != items.last?.id {
                        ByDivider()
                            .padding(.leading, 14)
                    }
                }
            }
            .byCard(padding: 0, radius: 18)
        }
    }

    private func foodRow(_ item: FoodItem) -> some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(ByFont.semibold(13.5))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                Text("\(Formatters.integer(item.calories)) ккал · Б \(Formatters.integer(item.protein)) · У \(Formatters.integer(item.carbs)) · Ж \(Formatters.integer(item.fat))")
                    .font(ByFont.regular(9.5))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 6)

            Text("\(Formatters.integer(item.defaultGrams)) г")
                .font(ByFont.mono(9.5, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: Manual

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Название")
                TextField("Например, домашний боул", text: $manualName)
                    .font(ByFont.regular(14))
                    .foregroundStyle(Theme.text)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .name)
                    .byField(minHeight: 48)
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Порция и калории")
                HStack(spacing: 9) {
                    numberInput("Граммы", text: $manualGrams, suffix: "г", field: .grams)
                    numberInput("Ккал", text: $manualCalories, suffix: "ккал", field: .calories)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldTitle("Макросы на порцию")
                HStack(spacing: 9) {
                    numberInput("Белки", text: $manualProtein, suffix: "г", field: .protein)
                    numberInput("Углеводы", text: $manualCarbs, suffix: "г", field: .carbs)
                    numberInput("Жиры", text: $manualFat, suffix: "г", field: .fat)
                }
            }

            Text("Макросы можно не указывать. Калории обязательны.")
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
                .padding(.horizontal, 4)
        }
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(ByFont.label)
            .tracking(0.8)
            .foregroundStyle(Theme.secondary)
    }

    private func numberInput(
        _ title: String,
        text: Binding<String>,
        suffix: String,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ByFont.regular(9.5))
                .foregroundStyle(Theme.tertiary)
            HStack(spacing: 3) {
                TextField("0", text: text)
                    .font(ByFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .multilineTextAlignment(.leading)
                Text(suffix)
                    .font(ByFont.regular(8.5))
                    .foregroundStyle(Theme.tertiary)
            }
            .byField(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }

    private var manualSaveButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)

            Button {
                saveManual()
            } label: {
                Text("Добавить в дневник")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!manualIsValid)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Theme.bg)
    }

    private func saveManual() {
        guard manualIsValid else { return }
        let name = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        let calories = decimalValue(manualCalories) ?? 0

        let entry = FoodEntry(
            date: date,
            name: name,
            meal: meal,
            grams: decimalValue(manualGrams),
            calories: calories,
            protein: decimalValue(manualProtein) ?? 0,
            carbs: decimalValue(manualCarbs) ?? 0,
            fat: decimalValue(manualFat) ?? 0
        )
        context.insert(entry)
        ProgramStore.save(context)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Meal picker

struct MealPickerRow: View {
    @Binding var selection: MealType

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MealType.allCases) { meal in
                Button {
                    selection = meal
                    Haptics.tap()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: meal.symbol)
                            .font(.system(size: 12, weight: .semibold))
                        Text(meal.title)
                            .font(ByFont.semibold(9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(selection == meal ? Theme.bg : Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selection == meal ? Color.white : Color.white.opacity(0.04),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                selection == meal ? Color.clear : Theme.stroke,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Portion

struct FoodPortionView: View {
    @Environment(\.modelContext) private var context

    let food: FoodItem
    let date: Date
    let onSaved: () -> Void

    @State private var meal: MealType
    @State private var gramsText: String
    @FocusState private var gramsFocused: Bool

    private let presets: [Double] = [50, 100, 150, 200, 250]

    init(
        food: FoodItem,
        date: Date,
        meal: MealType,
        onSaved: @escaping () -> Void
    ) {
        self.food = food
        self.date = date
        self.onSaved = onSaved
        _meal = State(initialValue: meal)
        _gramsText = State(
            initialValue: Formatters.number(food.defaultGrams, maxFraction: 0)
        )
    }

    private var grams: Double? {
        decimalValue(gramsText)
    }

    private var isValid: Bool {
        (grams ?? 0) > 0
    }

    private var portionCalories: Double {
        food.calories(for: grams ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                foodHeader
                portionCard
                mealCard
                macroCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(ByBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            saveButton
        }
        .navigationTitle("Порция")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var foodHeader: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: food.category.symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text(food.category.rawValue.uppercased())
                    .font(ByFont.label)
                    .tracking(1.1)
                    .foregroundStyle(Theme.red)
            }

            Text(food.name)
                .font(ByFont.display(30))
                .tracking(-0.8)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text("На 100 г: \(Formatters.integer(food.calories)) ккал · Б \(Formatters.integer(food.protein)) · У \(Formatters.integer(food.carbs)) · Ж \(Formatters.integer(food.fat))")
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.secondary)
        }
        .padding(.top, 4)
    }

    private var portionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("100", text: $gramsText)
                    .font(ByFont.display(44))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                    .keyboardType(.decimalPad)
                    .focused($gramsFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("г")
                    .font(ByFont.regular(14))
                    .foregroundStyle(Theme.tertiary)
            }

            HStack(spacing: 7) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        gramsText = Formatters.number(preset, maxFraction: 0)
                        Haptics.tap()
                    } label: {
                        Text("\(Formatters.integer(preset))")
                            .font(ByFont.mono(10, weight: .semibold))
                            .foregroundStyle(grams == preset ? Theme.bg : Theme.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                grams == preset ? Color.white : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 5) {
                Text("Порция")
                    .font(ByFont.regular(10.5))
                    .foregroundStyle(Theme.tertiary)
                Spacer()
                Text(Formatters.kcal(portionCalories))
                    .font(ByFont.mono(11, weight: .semibold))
                    .foregroundStyle(Theme.red)
            }
        }
        .byCard()
    }

    private var mealCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ПРИЁМ ПИЩИ")
                .font(ByFont.label)
                .tracking(1.1)
                .foregroundStyle(Theme.secondary)
            MealPickerRow(selection: $meal)
            Text(Formatters.fullDate(date))
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
                .padding(.top, 2)
        }
        .byCard()
    }

    private var macroCard: some View {
        HStack(spacing: 0) {
            macroValue("Белки", food.protein(for: grams ?? 0))
            macroDivider
            macroValue("Углеводы", food.carbs(for: grams ?? 0))
            macroDivider
            macroValue("Жиры", food.fat(for: grams ?? 0))
            macroDivider
            macroValue("Ккал", portionCalories)
        }
        .byCard(padding: 14, radius: 20)
    }

    private var macroDivider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(width: 1, height: 30)
    }

    private func macroValue(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Formatters.integer(value))
                .font(ByFont.heavy(17))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title.uppercased())
                .font(ByFont.micro)
                .tracking(0.4)
                .foregroundStyle(Theme.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var saveButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 16)

            Button {
                save()
            } label: {
                HStack(spacing: 7) {
                    Text("Добавить")
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isValid)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Theme.bg)
    }

    private func save() {
        guard let grams, grams > 0 else { return }

        let entry = FoodEntry(
            date: date,
            name: food.name,
            meal: meal,
            grams: grams,
            calories: food.calories(for: grams),
            protein: food.protein(for: grams),
            carbs: food.carbs(for: grams),
            fat: food.fat(for: grams)
        )
        context.insert(entry)
        ProgramStore.save(context)
        Haptics.success()
        onSaved()
    }
}

// MARK: - Parsing

private func decimalValue(_ text: String) -> Double? {
    let cleaned = text
        .replacingOccurrences(of: ",", with: ".")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty, let value = Double(cleaned), value >= 0 else {
        return nil
    }
    return value
}
