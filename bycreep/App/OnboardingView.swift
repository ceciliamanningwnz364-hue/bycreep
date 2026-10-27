import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var sex: Sex = .male
    @State private var age = 25
    @State private var height = 178.0
    @State private var weight = 78.0
    @State private var goal: Goal = .maintain
    @State private var activity: ActivityLevel = .moderate
    @State private var experience: Experience = .intermediate
    @State private var trainingDays = 4
    @State private var autoGenerate = true
    @State private var isCreating = false
    @State private var showingSaveError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                sectionLabel("01 · ТЫ")
                VStack(spacing: 12) {
                    nameField
                    HStack(spacing: 8) {
                        ForEach(Sex.allCases) { item in
                            ChoiceChip(title: item.title, isSelected: sex == item) {
                                sex = item
                                Haptics.tap()
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        numberField(
                            title: "Возраст",
                            suffix: "лет",
                            value: Binding(
                                get: { Double(age) },
                                set: { age = Int($0) }
                            ),
                            fractionDigits: 0
                        )
                        numberField(
                            title: "Рост",
                            suffix: "см",
                            value: $height,
                            fractionDigits: 0
                        )
                    }

                    numberField(
                        title: "Вес",
                        suffix: "кг",
                        value: $weight,
                        fractionDigits: 1
                    )
                }

                sectionLabel("02 · ЦЕЛЬ")
                VStack(alignment: .leading, spacing: 12) {
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

                sectionLabel("03 · РЕЖИМ")
                VStack(alignment: .leading, spacing: 18) {
                    activityBlock
                    ByDivider()
                    experienceBlock
                    ByDivider()
                    trainingDaysBlock
                }
                .byCard()

                sectionLabel("04 · ПЛАН")
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(isOn: $autoGenerate) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Собрать тяжёлую программу")
                                .font(ByFont.semibold(14))
                                .foregroundStyle(Theme.text)
                            Text("Сплит, упражнения и стартовые веса — по твоим параметрам")
                                .font(ByFont.regular(12))
                                .foregroundStyle(Theme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.red)

                    Text("Программа — ориентир, а не медицинская рекомендация. Следи за техникой и самочувствием.")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                        .lineSpacing(2)
                }
                .byCard()

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .safeAreaInset(edge: .bottom) {
            createButton
        }
        .alert("Не удалось сохранить", isPresented: $showingSaveError) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Данные не записались на диск. Попробуй создать профиль ещё раз.")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("bycreep")
                    .font(.system(size: 44, weight: .black, design: .default))
                    .tracking(-2.2)
                    .foregroundStyle(Theme.text)
                Circle()
                    .fill(Theme.red)
                    .frame(width: 9, height: 9)
                    .offset(y: -22)
            }

            Text("ТВОЙ ПРОГРЕСС.\nБЕЗ ШУМА.")
                .font(ByFont.display(27))
                .tracking(-0.7)
                .foregroundStyle(Theme.text)
                .lineSpacing(1)

            Text("Добавляй программы, фиксируй каждый подход, сравнивай месяц к месяцу. Всё в одном месте — быстро и без лишнего.")
                .font(ByFont.regular(14))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
        }
        .padding(.top, 20)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(ByFont.label)
            .tracking(1.4)
            .foregroundStyle(Theme.red)
            .padding(.top, 2)
    }

    // MARK: Fields

    private var nameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.secondary)
            TextField("Имя", text: $name)
                .font(ByFont.regular(15))
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
        }
        .byField()
    }

    private func numberField(
        title: String,
        suffix: String,
        value: Binding<Double>,
        fractionDigits: Int
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 8)
            TextField(
                "0",
                value: value,
                format: .number.precision(.fractionLength(0...fractionDigits))
            )
            .font(ByFont.heavy(17))
            .foregroundStyle(Theme.text)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .frame(minWidth: 54)
            Text(suffix)
                .font(ByFont.regular(12))
                .foregroundStyle(Theme.tertiary)
        }
        .byField(minHeight: 52)
    }

    private var activityBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldTitle("Активность в течение дня")
            HStack(spacing: 6) {
                ForEach(ActivityLevel.allCases) { item in
                    Button {
                        activity = item
                        Haptics.tap()
                    } label: {
                        Text(item.shortTitle)
                            .font(ByFont.semibold(11))
                            .foregroundStyle(activity == item ? Theme.bg : Theme.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                activity == item ? Color.white : Color.white.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(activity.title)
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.tertiary)
        }
    }

    private var experienceBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
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
    }

    private var trainingDaysBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                fieldTitle("Тренировок в неделю")
                Spacer()
                Text("\(trainingDays)")
                    .font(ByFont.display(28))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
            }

            HStack(spacing: 10) {
                stepperButton(systemName: "minus") {
                    trainingDays = max(2, trainingDays - 1)
                    Haptics.tap()
                }
                stepperButton(systemName: "plus") {
                    trainingDays = min(6, trainingDays + 1)
                    Haptics.tap()
                }
                Text(daysHint)
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .padding(.leading, 4)
                Spacer(minLength: 0)
            }
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.text)
                .frame(width: 38, height: 38)
                .background(Theme.surfaceSoft, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var daysHint: String {
        switch trainingDays {
        case 2: return "Full Body"
        case 3: return "Full Body"
        case 4: return "Upper / Lower"
        case 5: return "PPL + Upper / Lower"
        default: return "PPL ×2"
        }
    }

    private func fieldTitle(_ text: String) -> some View {
        Text(text)
            .font(ByFont.regular(13))
            .foregroundStyle(Theme.secondary)
    }

    // MARK: Create

    private var createButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 18)

            Button {
                createProfile()
            } label: {
                HStack(spacing: 8) {
                    Text(isCreating ? "Создаю…" : "Создать bycreep")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isCreating)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Theme.bg)
    }

    private func createProfile() {
        guard !isCreating else { return }
        isCreating = true

        let cleanAge = min(max(age, 14), 90)
        let cleanHeight = min(max(height, 120), 230)
        let cleanWeight = min(max(weight, 35), 250)

        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sex: sex,
            age: cleanAge,
            heightCm: cleanHeight,
            weightKg: cleanWeight,
            activity: activity,
            goal: goal,
            experience: experience,
            trainingDaysPerWeek: trainingDays
        )
        context.insert(profile)

        let firstMeasurement = BodyMeasurement(
            date: Date(),
            weightKg: cleanWeight,
            note: "Старт"
        )
        context.insert(firstMeasurement)

        if autoGenerate {
            let plan = WorkoutGenerator.generate(for: profile)
            guard ProgramStore.saveGenerated(plan, context: context) else {
                handleSaveFailure()
                return
            }
        }

        guard ProgramStore.save(context) else {
            handleSaveFailure()
            return
        }

        WidgetBridge.refresh(context: context)
        Haptics.success()
    }

    private func handleSaveFailure() {
        context.rollback()
        isCreating = false
        showingSaveError = true
    }
}
