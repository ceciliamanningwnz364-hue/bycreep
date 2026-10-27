import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context

    let profile: UserProfile

    @Query(sort: \Program.createdAt, order: .reverse)
    private var programs: [Program]

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @State private var showingEdit = false
    @State private var showingGenerator = false
    @State private var widgetNotice = false

    private var activeProgram: Program? {
        programs.first(where: \.isActive)
    }

    private var completedSessions: Int {
        sessions.filter(\.isCompleted).count
    }

    private var latestWeight: Double {
        measurements.first?.weightKg ?? profile.weightKg
    }

    private var bmi: Double {
        guard profile.heightCm > 0 else { return 0 }
        return latestWeight / pow(profile.heightCm / 100, 2)
    }

    private var plan: NutritionPlan {
        NutritionCalculator.plan(for: profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                identityCard
                metricsCard
                parametersCard
                nutritionCard
                trainingCard
                widgetCard
                dataCard
                signature
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEdit) {
            ProfileEditView(profile: profile)
        }
        .sheet(isPresented: $showingGenerator) {
            GeneratorView(profile: profile)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ScreenTitle(eyebrow: "05 · Личное", title: "Профиль")

            Spacer(minLength: 8)

            Button {
                showingEdit = true
                Haptics.tap()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceElevated, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Изменить профиль")
        }
    }

    // MARK: Identity

    private var identityCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceElevated)
                Circle()
                    .strokeBorder(Theme.stroke, lineWidth: 1)
                Text(profile.initials)
                    .font(ByFont.display(23))
                    .foregroundStyle(Theme.text)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.displayName)
                    .font(ByFont.heavy(21))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    Text(profile.goal.title)
                        .font(ByFont.semibold(10))
                        .foregroundStyle(Theme.red)
                    Text("·")
                        .foregroundStyle(Theme.tertiary)
                    Text(profile.experience.title)
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.secondary)
                }

                Text("Закрыто: \(Formatters.workouts(completedSessions))")
                    .font(ByFont.regular(10))
                    .foregroundStyle(Theme.tertiary)
            }

            Spacer(minLength: 0)

            Button {
                showingEdit = true
                Haptics.tap()
            } label: {
                Text("Изменить")
                    .font(ByFont.semibold(11))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .byCard()
    }

    // MARK: Metrics

    private var metricsCard: some View {
        HStack(spacing: 0) {
            metric(
                value: Formatters.number(latestWeight),
                caption: "Вес, кг",
                symbol: "scalemass"
            )
            metricDivider
            metric(
                value: Formatters.number(profile.heightCm, maxFraction: 0),
                caption: "Рост, см",
                symbol: "ruler"
            )
            metricDivider
            metric(
                value: "\(profile.age)",
                caption: "Возраст",
                symbol: "person"
            )
            metricDivider
            metric(
                value: Formatters.number(bmi, maxFraction: 1),
                caption: "ИМТ",
                symbol: "chart.bar"
            )
        }
        .byCard(padding: 14, radius: 20)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(width: 1, height: 34)
    }

    private func metric(value: String, caption: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text(value)
                    .font(ByFont.heavy(16))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Text(caption.uppercased())
                .font(ByFont.micro)
                .tracking(0.3)
                .foregroundStyle(Theme.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    // MARK: Parameters

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Параметры",
                subtitle: "Влияют на программу и норму калорий",
                actionTitle: "Изменить",
                action: {
                    showingEdit = true
                    Haptics.tap()
                }
            )

            VStack(spacing: 12) {
                InfoRow(title: "Пол", value: profile.sex.title, symbol: "person")
                ByDivider()
                InfoRow(
                    title: "Активность",
                    value: profile.activity.shortTitle,
                    symbol: "figure.walk"
                )
                ByDivider()
                InfoRow(
                    title: "Цель",
                    value: profile.goal.title,
                    symbol: profile.goal.symbol
                )
                ByDivider()
                InfoRow(
                    title: "Опыт",
                    value: profile.experience.title,
                    symbol: "chart.line.uptrend.xyaxis"
                )
                ByDivider()
                InfoRow(
                    title: "Дней в неделю",
                    value: "\(profile.trainingDaysPerWeek)",
                    symbol: "calendar"
                )
            }
            .byCard()
        }
    }

    // MARK: Nutrition

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("ПИТАНИЕ")
                    .font(ByFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("АВТОРАСЧЁТ")
                    .font(ByFont.micro)
                    .tracking(0.7)
                    .foregroundStyle(Theme.red)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(Formatters.integer(plan.calories))
                    .font(ByFont.display(35))
                    .tracking(-1)
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                Text("ккал / день")
                    .font(ByFont.regular(12))
                    .foregroundStyle(Theme.tertiary)
                Spacer()
                Text(profile.goal.title.uppercased())
                    .font(ByFont.micro)
                    .tracking(0.5)
                    .foregroundStyle(Theme.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.redSoft, in: Capsule())
            }

            HStack(spacing: 7) {
                macroTag("Белки", plan.protein)
                macroTag("Углеводы", plan.carbs)
                macroTag("Жиры", plan.fat)
            }

            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text("Вода \(Formatters.integer(plan.waterML)) мл")
                    .font(ByFont.mono(10, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text("BMR \(Formatters.integer(plan.bmr)) · TDEE \(Formatters.integer(plan.tdee))")
                    .font(ByFont.mono(9, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text("Формула Миффлина–Сан Жеора + уровень активности и цель. Вес берётся из профиля.")
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
                .lineSpacing(2)
        }
        .byCard()
    }

    private func macroTag(_ title: String, _ grams: Double) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(Theme.tertiary)
            Text("\(Formatters.integer(grams)) г")
                .foregroundStyle(Theme.text)
                .font(ByFont.mono(9.5, weight: .semibold))
        }
        .font(ByFont.regular(9.5))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.045), in: Capsule())
    }

    // MARK: Training

    private var trainingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Программа", subtitle: "Тяжёлый сплит под твои параметры")

            if let activeProgram {
                VStack(alignment: .leading, spacing: 11) {
                    Text(activeProgram.name)
                        .font(ByFont.heavy(19))
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)

                    HStack(spacing: 7) {
                        TagPill(text: Formatters.days(activeProgram.days.count))
                        TagPill(text: "\(activeProgram.totalExercises) упражн.")
                        TagPill(text: activeProgram.source == "generated" ? "AUTO" : "MANUAL")
                    }

                    HStack(spacing: 5) {
                        ForEach(activeProgram.trainingWeekdays, id: \.self) { weekday in
                            Text(Formatters.weekdayShort(weekday))
                                .font(ByFont.micro)
                                .tracking(0.3)
                                .foregroundStyle(Theme.text)
                                .frame(width: 30, height: 23)
                                .background(Color.white.opacity(0.07), in: Capsule())
                        }
                        Spacer()
                    }
                }
                .byCard()
            } else {
                Text("Активной программы пока нет. Собери её автоматически или добавь вручную во вкладке «Зал».")
                    .font(ByFont.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineSpacing(3)
                    .byCard()
            }

            Button {
                showingGenerator = true
                Haptics.tap()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text(activeProgram == nil ? "Собрать программу" : "Пересобрать программу")
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    // MARK: Widget

    private var widgetCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Theme.redSoft)
                        .frame(width: 42, height: 42)
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.red)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Виджет недели")
                        .font(ByFont.semibold(14))
                        .foregroundStyle(Theme.text)
                    Text("Чёрный фон · ПН–ВС · сегодня красным")
                        .font(ByFont.regular(10.5))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 4)
            }

            Text("Зажми домашний экран → «+» → bycreep. Выбери размер и добавь виджет. Тренировочный день будет светиться красным.")
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)

            Button {
                WidgetBridge.refresh(context: context)
                widgetNotice = true
                Haptics.success()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_300_000_000)
                    widgetNotice = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: widgetNotice ? "checkmark" : "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                    Text(widgetNotice ? "Виджет обновлён" : "Обновить виджет")
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
        .byCard()
    }

    // MARK: Data

    private var dataCard: some View {
        VStack(spacing: 12) {
            InfoRow(
                title: "Данные",
                value: "Только на этом iPhone",
                symbol: "lock.fill"
            )
            ByDivider()
            InfoRow(
                title: "Версия",
                value: appVersion,
                symbol: "info.circle"
            )
        }
        .byCard()
    }

    private var signature: some View {
        HStack(spacing: 2) {
            Text("bycreep")
                .font(.system(size: 14, weight: .black))
                .tracking(-0.4)
                .foregroundStyle(Theme.secondary)
            Circle()
                .fill(Theme.red)
                .frame(width: 3, height: 3)
                .offset(y: -4)
            Spacer()
            Text("ТВОЙ ПРОГРЕСС. БЕЗ ШУМА.")
                .font(ByFont.micro)
                .tracking(0.8)
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
