import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context

    @Bindable var profile: UserProfile
    @Binding var selection: Int

    @Query(sort: \Program.createdAt, order: .reverse)
    private var programs: [Program]

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @State private var workoutSession: WorkoutSession?
    @State private var showingWorkout = false
    @State private var showingGenerator = false

    private var activeProgram: Program? {
        programs.first(where: { $0.isActive })
    }

    private var todayWeekday: Int {
        WeekClock.weekdayIndex(for: Date())
    }

    private var todayPlan: (program: Program, day: ProgramDay)? {
        guard let program = activeProgram,
              let day = program.days.first(where: { $0.weekday == todayWeekday }) else {
            return nil
        }
        return (program, day)
    }

    private var unfinishedSession: WorkoutSession? {
        let cutoff = SessionFactory.resumeCutoffDate()
        return sessions.first {
            !$0.isCompleted && $0.date >= cutoff
        }
    }

    private var completedToday: WorkoutSession? {
        sessions.first {
            $0.isCompleted && WeekClock.isSameDay($0.date, Date())
        }
    }

    private var latestMeasurement: BodyMeasurement? {
        measurements.first
    }

    private var weekCompletedSessions: [WorkoutSession] {
        let keys = Set(WeekClock.weekDates(containing: Date()).map(WeekClock.dateKey))
        return sessions.filter {
            $0.isCompleted && keys.contains(WeekClock.dateKey($0.date))
        }
    }

    private var weekCompletedKeys: Set<String> {
        Set(weekCompletedSessions.map { WeekClock.dateKey($0.date) })
    }

    private var trainingWeekdays: Set<Int> {
        Set(activeProgram?.trainingWeekdays ?? [])
    }

    private var recentSessions: [WorkoutSession] {
        Array(sessions.filter(\.isCompleted).prefix(3))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader
                weekCard
                workoutHero
                quickStats
                NutritionTodayCard(profile: profile) {
                    selection = 3
                    Haptics.tap()
                }
                recentWorkouts
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingGenerator) {
            GeneratorView(profile: profile)
        }
        .fullScreenCover(isPresented: $showingWorkout) {
            if let workoutSession {
                WorkoutSessionView(session: workoutSession)
                    .preferredColorScheme(.dark)
            }
        }
        .onChange(of: showingWorkout) { _, isPresented in
            if !isPresented {
                workoutSession = nil
            }
        }
    }

    // MARK: Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("bycreep")
                        .font(.system(size: 24, weight: .black))
                        .tracking(-1)
                        .foregroundStyle(Theme.text)
                    Circle()
                        .fill(Theme.red)
                        .frame(width: 5, height: 5)
                        .offset(y: -10)
                }

                Spacer()

                Button {
                    selection = 4
                    Haptics.tap()
                } label: {
                    Text(profile.initials)
                        .font(ByFont.heavy(12))
                        .foregroundStyle(Theme.text)
                        .frame(width: 38, height: 38)
                        .background(Theme.surfaceElevated, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Профиль")
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("\(WeekClock.fullLabels[todayWeekday - 1].uppercased()) · \(Formatters.dayMonthUppercased(Date()))")
                    .font(ByFont.label)
                    .tracking(1.4)
                    .foregroundStyle(Theme.red)
                Text("Сегодня")
                    .font(ByFont.display(38))
                    .tracking(-1.3)
                    .foregroundStyle(Theme.text)
                Text("\(profile.displayName), вот твой день. Работай чисто.")
                    .font(ByFont.regular(13))
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 1)
            }
        }
    }

    // MARK: Week

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .firstTextBaseline) {
                Text("НЕДЕЛЯ")
                    .font(ByFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Text(activeProgram?.name ?? "Программа не выбрана")
                    .font(ByFont.semibold(11))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 190, alignment: .trailing)
            }

            WeekStripView(
                trainingWeekdays: trainingWeekdays,
                completedDateKeys: weekCompletedKeys,
                today: Date()
            )
        }
        .byCard()
    }

    // MARK: Hero

    @ViewBuilder
    private var workoutHero: some View {
        if let unfinishedSession,
           WeekClock.isToday(unfinishedSession.date) || completedToday == nil {
            resumeCard(unfinishedSession)
        } else if let completedToday {
            completedCard(completedToday)
        } else if let todayPlan {
            startCard(program: todayPlan.program, day: todayPlan.day)
        } else if activeProgram != nil {
            restCard
        } else {
            noProgramCard
        }
    }

    private func startCard(program: Program, day: ProgramDay) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Theme.red)
                            .frame(width: 6, height: 6)
                        Text("ПРОГРАММА ДНЯ")
                            .font(ByFont.label)
                            .tracking(1.4)
                            .foregroundStyle(Theme.red)
                    }

                    Text(day.title)
                        .font(ByFont.display(31))
                        .tracking(-1)
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(day.exercises.count)")
                        .font(ByFont.display(26))
                        .foregroundStyle(Theme.text)
                    Text("УПРАЖН.")
                        .font(ByFont.micro)
                        .tracking(0.7)
                        .foregroundStyle(Theme.tertiary)
                }
            }

            Text(
                day.exercises.isEmpty
                    ? "В этом дне пока нет упражнений. Добавь их в редакторе программы."
                    : day.orderedExercises.prefix(3).map(\.name).joined(separator: " · ")
            )
            .font(ByFont.regular(12))
            .foregroundStyle(day.exercises.isEmpty ? Theme.tertiary : Theme.secondary)
            .lineLimit(2)
            .padding(.top, 12)

            HStack(spacing: 18) {
                heroMetric(symbol: "clock", value: "~\(day.estimatedMinutes) мин")
                heroMetric(symbol: "square.stack.3d.up", value: Formatters.sets(day.totalSets))
                heroMetric(symbol: "flame", value: "тяжёлый")
            }
            .padding(.top, 18)

            Button {
                startWorkout(program: program, day: day)
            } label: {
                HStack(spacing: 8) {
                    Text("Начать тренировку")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .heavy))
                }
            }
            .buttonStyle(LightButtonStyle())
            .disabled(day.exercises.isEmpty)
            .opacity(day.exercises.isEmpty ? 0.5 : 1)
            .padding(.top, 20)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.heroGradient)
                .overlay {
                    RadialGradient(
                        colors: [Theme.red.opacity(0.20), .clear],
                        center: .topTrailing,
                        startRadius: 10,
                        endRadius: 280
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Theme.red.opacity(0.20), lineWidth: 1)
                }
        }
    }

    private func heroMetric(symbol: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.red)
            Text(value)
                .font(ByFont.semibold(11))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
    }

    private func resumeCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TagPill(text: "Пауза", color: Theme.bg, fill: Theme.text)
                Spacer()
                Text(resumeDateLabel(session))
                    .font(ByFont.mono(11, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ТРЕНИРОВКА В ПРОЦЕССЕ")
                    .font(ByFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.red)
                Text(session.title)
                    .font(ByFont.display(28))
                    .foregroundStyle(Theme.text)
                Text("\(Formatters.sets(session.completedSets)) из \(session.totalSets) отмечено")
                    .font(ByFont.regular(12))
                    .foregroundStyle(Theme.secondary)
            }

            Button {
                workoutSession = session
                showingWorkout = true
                Haptics.impact()
            } label: {
                HStack(spacing: 8) {
                    Text("Продолжить")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .heavy))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .byCard(padding: 20)
    }

    private func resumeDateLabel(_ session: WorkoutSession) -> String {
        let time = Formatters.time(session.date)
        if WeekClock.isToday(session.date) {
            return time
        }
        return "\(Formatters.shortDate(session.date)) · \(time)"
    }

    private func completedCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.red)
                    Text("ТРЕНИРОВКА ЗАКРЫТА")
                        .font(ByFont.label)
                        .tracking(1.2)
                        .foregroundStyle(Theme.text)
                }
                Spacer()
                Text(Formatters.time(session.finishedAt ?? session.date))
                    .font(ByFont.mono(11, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
            }

            Text(session.title)
                .font(ByFont.display(28))
                .foregroundStyle(Theme.text)

            HStack(spacing: 0) {
                completedMetric(value: session.durationLabel, title: "Время")
                Rectangle()
                    .fill(Theme.stroke)
                    .frame(width: 1, height: 30)
                completedMetric(value: "\(session.completedSets)", title: "Подходов")
                Rectangle()
                    .fill(Theme.stroke)
                    .frame(width: 1, height: 30)
                completedMetric(value: Formatters.volume(session.totalVolume), title: "Объём")
            }

            Button {
                selection = 2
                Haptics.tap()
            } label: {
                Text("Смотреть прогресс")
            }
            .buttonStyle(GhostButtonStyle())
        }
        .byCard(padding: 20)
    }

    private func completedMetric(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(ByFont.heavy(17))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(title.uppercased())
                .font(ByFont.micro)
                .tracking(0.5)
                .foregroundStyle(Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var restCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text("ДЕНЬ ВОССТАНОВЛЕНИЯ")
                    .font(ByFont.label)
                    .tracking(1.2)
                    .foregroundStyle(Theme.red)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Рост происходит\nв отдыхе")
                    .font(ByFont.display(28))
                    .foregroundStyle(Theme.text)
                    .lineSpacing(1)
                Text(restSubtitle)
                    .font(ByFont.regular(13))
                    .foregroundStyle(Theme.secondary)
                    .lineSpacing(3)
                    .padding(.top, 3)
            }

            Button {
                selection = 1
                Haptics.tap()
            } label: {
                Text("Открыть программу")
            }
            .buttonStyle(GhostButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard(padding: 20)
    }

    private var restSubtitle: String {
        guard let program = activeProgram else {
            return "Сегодня тренировки нет."
        }
        let nextDate = WeekClock.nextTrainingDate(
            after: Date(),
            weekdays: program.trainingWeekdays
        )
        guard let nextDate else { return "Расписание пока не задано." }
        let title = program.days.first {
            $0.weekday == WeekClock.weekdayIndex(for: nextDate)
        }?.title
        let dateText = Formatters.relativeTrainingDate(nextDate)
        if let title {
            return "Следующая тренировка: \(dateText.lowercased()), \(title). Сон, вода и белок — тоже тренировка."
        }
        return "Следующая тренировка: \(dateText.lowercased())."
    }

    private var noProgramCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ПЕРВЫЙ ШАГ")
                .font(ByFont.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)

            Text("Собери свою\nтяжёлую программу")
                .font(ByFont.display(29))
                .foregroundStyle(Theme.text)
                .lineSpacing(1)

            Text("Подберу сплит, упражнения, подходы и стартовые веса по твоим параметрам. Дальше — правь под себя.")
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(3)

            Button {
                showingGenerator = true
                Haptics.tap()
            } label: {
                Text("Подобрать программу")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .byCard(padding: 20)
    }

    // MARK: Quick stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            StatTile(
                title: "Вес",
                value: Formatters.kg(latestMeasurement?.weightKg ?? profile.weightKg),
                detail: weightDetail,
                symbol: "scalemass",
                accent: Theme.red
            )

            StatTile(
                title: "Неделя",
                value: weekGoalValue,
                detail: weekCompletedSessions.isEmpty ? "пока без тренировок" : "тренировок закрыто",
                symbol: "flame.fill",
                accent: Theme.red
            )
        }
    }

    private var weekGoalValue: String {
        guard let program = activeProgram else { return "—" }
        return "\(weekCompletedSessions.count)/\(program.trainingWeekdays.count)"
    }

    private var weightDetail: String {
        guard let latest = latestMeasurement else { return "добавь замер" }
        guard measurements.count > 1 else { return "стартовый вес" }
        let previous = measurements[1]
        let diff = latest.weightKg - previous.weightKg
        if abs(diff) < 0.05 { return "без изменений" }
        let arrow = diff > 0 ? "↑" : "↓"
        return "\(arrow) \(Formatters.number(abs(diff))) кг"
    }

    // MARK: Recent workouts

    @ViewBuilder
    private var recentWorkouts: some View {
        if !recentSessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(
                    title: "Последние",
                    actionTitle: "История",
                    action: {
                        selection = 2
                        Haptics.tap()
                    }
                )

                VStack(spacing: 0) {
                    ForEach(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                        sessionRow(session)
                        if index < recentSessions.count - 1 {
                            ByDivider()
                        }
                    }
                }
                .byCard(padding: 0)
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Theme.redSoft)
                    .frame(width: 42, height: 42)
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Theme.red)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(ByFont.semibold(14))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text("\(Formatters.shortDate(session.date)) · \(session.durationLabel) · \(Formatters.sets(session.completedSets))")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(Formatters.volume(session.totalVolume))
                .font(ByFont.mono(11, weight: .medium))
                .foregroundStyle(Theme.secondary)
        }
        .padding(14)
    }

    // MARK: Actions

    private func startWorkout(program: Program, day: ProgramDay) {
        guard !day.exercises.isEmpty else {
            Haptics.warning()
            return
        }

        let session = SessionFactory.makeSession(
            day: day,
            program: program,
            context: context
        )
        workoutSession = session
        showingWorkout = true
        Haptics.heavy()
    }
}
