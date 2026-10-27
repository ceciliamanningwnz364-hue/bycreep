import SwiftUI
import SwiftData

struct GeneratorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile

    @State private var trainingDays: Int
    @State private var plan: TrainingPlan
    @State private var isSaving = false
    @State private var showingSaveError = false

    init(profile: UserProfile) {
        self.profile = profile
        let days = min(max(profile.trainingDaysPerWeek, 2), 6)
        _trainingDays = State(initialValue: days)
        _plan = State(initialValue: WorkoutGenerator.generate(for: profile, trainingDays: days))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    parametersCard
                    daysCard
                    planOverview
                    exercisePlan
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 36, height: 36)
                            .background(Theme.surfaceElevated, in: Circle())
                    }
                }
            }
        }
        .alert("Не удалось сохранить", isPresented: $showingSaveError) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Программа не записалась на диск. Попробуй создать её ещё раз.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ПЕРСОНАЛЬНЫЙ ПЛАН")
                .font(ByFont.label)
                .tracking(1.6)
                .foregroundStyle(Theme.red)
            Text("Тяжёлая\nпрограмма")
                .font(ByFont.display(36))
                .tracking(-1.2)
                .foregroundStyle(Theme.text)
                .lineSpacing(1)
            Text("Собрано под \(profile.displayName), вес \(Formatters.kg(profile.weightKg)), опыт: \(profile.experience.title.lowercased()).")
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(plan.name)
                .font(ByFont.heavy(19))
                .foregroundStyle(Theme.text)
            Text(plan.subtitle)
                .font(ByFont.regular(12))
                .foregroundStyle(Theme.secondary)

            HStack(spacing: 6) {
                TagPill(text: profile.goal.title)
                TagPill(text: profile.experience.title)
                TagPill(text: Formatters.workouts(plan.days.count))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    private var daysCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ДНЕЙ В НЕДЕЛЮ")
                    .font(ByFont.label)
                    .tracking(1)
                    .foregroundStyle(Theme.secondary)
                Text("Сплит пересоберётся")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
            }

            Spacer()

            HStack(spacing: 10) {
                dayButton(systemName: "minus", enabled: trainingDays > 2) {
                    trainingDays = max(2, trainingDays - 1)
                    regenerate()
                }

                Text("\(trainingDays)")
                    .font(ByFont.display(26))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                    .frame(minWidth: 28)

                dayButton(systemName: "plus", enabled: trainingDays < 6) {
                    trainingDays = min(6, trainingDays + 1)
                    regenerate()
                }
            }
        }
        .byCard()
    }

    private func dayButton(
        systemName: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(enabled ? Theme.text : Theme.tertiary)
                .frame(width: 36, height: 36)
                .background(Theme.surfaceSoft, in: Circle())
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var planOverview: some View {
        HStack(spacing: 10) {
            StatTile(
                title: "Дней",
                value: "\(plan.days.count)",
                detail: "в неделю",
                symbol: "calendar"
            )
            StatTile(
                title: "Подходов",
                value: "\(plan.days.reduce(0) { $0 + $1.totalSets })",
                detail: "за неделю",
                symbol: "square.stack.3d.up.fill"
            )
            StatTile(
                title: "Время",
                value: "~\(plan.days.map(\.estimatedMinutes).max() ?? 0)",
                detail: "мин / день",
                symbol: "clock.fill"
            )
        }
    }

    private var exercisePlan: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Содержание", subtitle: "Проверь дни и упражнения перед созданием")

            ForEach(plan.days, id: \.id) { day in
                dayCard(day)
            }
        }
    }

    private func dayCard(_ day: TrainingPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Formatters.weekdayShort(day.weekday))
                        .font(ByFont.label)
                        .tracking(1.1)
                        .foregroundStyle(Theme.red)
                    Text(day.title)
                        .font(ByFont.heavy(20))
                        .foregroundStyle(Theme.text)
                    Text(day.focus)
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("~\(day.estimatedMinutes) мин")
                        .font(ByFont.mono(10, weight: .medium))
                        .foregroundStyle(Theme.tertiary)
                    Text(Formatters.sets(day.totalSets))
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.tertiary)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(day.exercises.enumerated()), id: \.offset) { index, exercise in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(ByFont.mono(10, weight: .medium))
                            .foregroundStyle(Theme.tertiary)
                            .frame(width: 16, alignment: .leading)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(ByFont.semibold(13))
                                .foregroundStyle(Theme.text)
                                .lineLimit(2)
                            Text(exercise.muscle)
                                .font(ByFont.regular(10))
                                .foregroundStyle(Theme.tertiary)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(exercise.sets) × \(exercise.repsLabel)")
                                .font(ByFont.mono(11, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Text(weightLabel(exercise))
                                .font(ByFont.regular(10))
                                .foregroundStyle(Theme.tertiary)
                        }
                    }
                    .padding(.vertical, 8)

                    if index < day.exercises.count - 1 {
                        ByDivider()
                    }
                }
            }
        }
        .byCard()
    }

    private func weightLabel(_ exercise: TrainingPlanExercise) -> String {
        if let weight = exercise.targetWeightKg {
            return "старт \(Formatters.number(weight)) кг"
        }
        return "свой вес"
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.red)
                .padding(.top, 2)
            Text("Стартовые веса рассчитаны приблизительно. Начни легче, отработай технику и добавь вес, когда верх диапазона повторений стабильно получается. Это не медицинская рекомендация.")
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(2)
        }
        .byCard(padding: 14, radius: 18)
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
                HStack(spacing: 8) {
                    Text(isSaving ? "Создаю…" : "Создать программу")
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSaving)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Theme.bg)
    }

    private func regenerate() {
        withAnimation(.easeOut(duration: 0.2)) {
            plan = WorkoutGenerator.generate(for: profile, trainingDays: trainingDays)
        }
        Haptics.tap()
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        profile.trainingDaysPerWeek = trainingDays
        guard ProgramStore.saveGenerated(plan, context: context) else {
            context.rollback()
            isSaving = false
            showingSaveError = true
            return
        }

        Haptics.success()
        dismiss()
    }
}
