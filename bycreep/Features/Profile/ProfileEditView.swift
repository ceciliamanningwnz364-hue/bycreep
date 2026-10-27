import SwiftUI
import SwiftData
import UIKit

struct ProfileEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @State private var name: String
    @State private var sex: Sex
    @State private var ageText: String
    @State private var heightText: String
    @State private var weightText: String
    @State private var goal: Goal
    @State private var activity: ActivityLevel
    @State private var experience: Experience
    @State private var trainingDays: Int

    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _sex = State(initialValue: profile.sex)
        _ageText = State(initialValue: String(profile.age))
        _heightText = State(initialValue: Formatters.number(profile.heightCm, maxFraction: 0))
        _weightText = State(initialValue: Formatters.number(profile.weightKg, maxFraction: 1))
        _goal = State(initialValue: profile.goal)
        _activity = State(initialValue: profile.activity)
        _experience = State(initialValue: profile.experience)
        _trainingDays = State(initialValue: min(max(profile.trainingDaysPerWeek, 2), 6))
    }

    private var parsedAge: Int? {
        guard let value = parseNumber(ageText), (14...90).contains(value) else {
            return nil
        }
        return Int(value)
    }

    private var parsedHeight: Double? {
        guard let value = parseNumber(heightText), (120...230).contains(value) else {
            return nil
        }
        return value
    }

    private var parsedWeight: Double? {
        guard let value = parseNumber(weightText), (35...250).contains(value) else {
            return nil
        }
        return value
    }

    private var isValid: Bool {
        parsedAge != nil && parsedHeight != nil && parsedWeight != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    personalCard
                    bodyCard
                    goalCard
                    activityCard
                    experienceCard
                    trainingDaysCard
                    footnote
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(ByFont.semibold(13))
                    .foregroundStyle(Theme.secondary)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        dismissKeyboard()
                    }
                    .foregroundStyle(Theme.text)
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("ПАРАМЕТРЫ")
                .font(ByFont.label)
                .tracking(1.5)
                .foregroundStyle(Theme.red)
            Text("Изменить\nпрофиль")
                .font(ByFont.display(34))
                .tracking(-1.1)
                .foregroundStyle(Theme.text)
                .lineSpacing(1)
            Text("Норма питания и рекомендации пересчитаются автоматически.")
                .font(ByFont.regular(12))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)
        }
        .padding(.top, 6)
    }

    // MARK: Personal

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldTitle("Имя")
            TextField("Как тебя называть", text: $name)
                .font(ByFont.regular(15))
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .byField()

            fieldTitle("Пол")
            HStack(spacing: 8) {
                ForEach(Sex.allCases) { item in
                    ChoiceChip(title: item.title, isSelected: sex == item) {
                        sex = item
                        Haptics.tap()
                    }
                }
            }
        }
        .byCard()
    }

    // MARK: Body

    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            fieldTitle("Тело")
            HStack(spacing: 9) {
                numberField(title: "Возраст", text: $ageText, suffix: "лет", keyboard: .numberPad)
                numberField(title: "Рост", text: $heightText, suffix: "см")
            }
            numberField(title: "Вес", text: $weightText, suffix: "кг")

            Text("Вес синхронизируется с замерами и графиком прогресса.")
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
                .lineSpacing(2)
        }
        .byCard()
    }

    // MARK: Goal

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Цель")
            HStack(spacing: 8) {
                ForEach(Goal.allCases) { item in
                    ChoiceChip(title: item.title, isSelected: goal == item) {
                        goal = item
                        Haptics.tap()
                    }
                }
            }
            Text(goal.subtitle.uppercased())
                .font(ByFont.mono(10, weight: .medium))
                .tracking(1)
                .foregroundStyle(Theme.red)
        }
        .byCard()
    }

    // MARK: Activity

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Активность в течение дня")
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 7),
                    GridItem(.flexible(), spacing: 7),
                    GridItem(.flexible(), spacing: 7)
                ],
                spacing: 7
            ) {
                ForEach(ActivityLevel.allCases) { item in
                    ChoiceChip(title: item.shortTitle, isSelected: activity == item) {
                        activity = item
                        Haptics.tap()
                    }
                }
            }
            Text(activity.title)
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.tertiary)
        }
        .byCard()
    }

    // MARK: Experience

    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldTitle("Опыт тренировок")
            HStack(spacing: 8) {
                ForEach(Experience.allCases) { item in
                    ChoiceChip(title: item.title, isSelected: experience == item) {
                        experience = item
                        Haptics.tap()
                    }
                }
            }
        }
        .byCard()
    }

    // MARK: Training days

    private var trainingDaysCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                fieldTitle("Тренировок в неделю")
                Text("Для новых программ")
                    .font(ByFont.regular(10.5))
                    .foregroundStyle(Theme.tertiary)
            }

            Spacer()

            HStack(spacing: 10) {
                stepButton(systemName: "minus", enabled: trainingDays > 2) {
                    trainingDays = max(2, trainingDays - 1)
                    Haptics.tap()
                }

                Text("\(trainingDays)")
                    .font(ByFont.display(26))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                    .frame(minWidth: 28)

                stepButton(systemName: "plus", enabled: trainingDays < 6) {
                    trainingDays = min(6, trainingDays + 1)
                    Haptics.tap()
                }
            }
        }
        .byCard()
    }

    private func stepButton(
        systemName: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(enabled ? Theme.text : Theme.tertiary)
                .frame(width: 36, height: 36)
                .background(Theme.surfaceSoft, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: Fields

    private func fieldTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(ByFont.label)
            .tracking(0.9)
            .foregroundStyle(Theme.secondary)
    }

    private func numberField(
        title: String,
        text: Binding<String>,
        suffix: String,
        keyboard: UIKeyboardType = .decimalPad
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ByFont.regular(10))
                .foregroundStyle(Theme.tertiary)
            HStack(spacing: 4) {
                TextField("0", text: text)
                    .font(ByFont.mono(14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .keyboardType(keyboard)
                    .frame(maxWidth: .infinity)
                Text(suffix)
                    .font(ByFont.regular(9))
                    .foregroundStyle(Theme.tertiary)
            }
            .byField(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Footer

    private var footnote: some View {
        Text("Смена параметров не пересобирает текущую программу автоматически — сделай это кнопкой «Пересобрать» в профиле.")
            .font(ByFont.regular(10.5))
            .foregroundStyle(Theme.tertiary)
            .lineSpacing(2)
            .padding(.horizontal, 4)
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
                    Text("Сохранить")
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

    // MARK: Save

    private func save() {
        guard let age = parsedAge,
              let height = parsedHeight,
              let weight = parsedWeight else {
            return
        }

        let previousWeight = profile.weightKg

        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.sex = sex
        profile.age = age
        profile.heightCm = height
        profile.weightKg = weight
        profile.goal = goal
        profile.activity = activity
        profile.experience = experience
        profile.trainingDaysPerWeek = trainingDays

        if abs(weight - previousWeight) >= 0.05 {
            if let latest = measurements.first,
               WeekClock.isSameDay(latest.date, Date()) {
                latest.weightKg = weight
                if latest.note.isEmpty {
                    latest.note = "Обновление профиля"
                }
            } else {
                context.insert(
                    BodyMeasurement(
                        date: Date(),
                        weightKg: weight,
                        note: "Обновление профиля"
                    )
                )
            }
        }

        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Parsing

private func parseNumber(_ text: String) -> Double? {
    let cleaned = text
        .replacingOccurrences(of: ",", with: ".")
        .replacingOccurrences(of: "\u{00A0}", with: "")
        .replacingOccurrences(of: "\u{202F}", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty, let value = Double(cleaned), value > 0 else {
        return nil
    }
    return value
}

private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
