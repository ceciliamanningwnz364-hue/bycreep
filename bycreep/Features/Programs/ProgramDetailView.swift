import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var program: Program

    @State private var showingEditor = false
    @State private var workoutSession: WorkoutSession?
    @State private var showingWorkout = false
    @State private var showingDeleteAlert = false
    @State private var pendingDay: ProgramDay?
    @State private var conflictSession: WorkoutSession?
    @State private var conflictTitle = ""
    @State private var showingConflictAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerCard

                if program.days.isEmpty {
                    EmptyStateView(
                        symbol: "calendar.badge.plus",
                        title: "Нет тренировочных дней",
                        message: "Добавь день и упражнения в редакторе программы.",
                        actionTitle: "Изменить программу",
                        action: { showingEditor = true }
                    )
                    .byCard()
                } else {
                    SectionHeader(
                        title: "Дни",
                        subtitle: "\(Formatters.days(program.days.count)) в расписании"
                    )

                    ForEach(program.orderedDays, id: \.id) { day in
                        dayCard(day)
                    }
                }

                if !program.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ЗАМЕТКИ")
                            .font(ByFont.label)
                            .tracking(1.2)
                            .foregroundStyle(Theme.secondary)
                        Text(program.notes)
                            .font(ByFont.regular(12))
                            .foregroundStyle(Theme.secondary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .byCard()
                }

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Text("Удалить программу")
                        .font(ByFont.semibold(13))
                        .foregroundStyle(Theme.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .navigationTitle("Программа")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Theme.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingEditor) {
            ProgramEditorView(program: program)
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
        .alert("Удалить программу?", isPresented: $showingDeleteAlert) {
            Button("Удалить", role: .destructive) {
                ProgramStore.delete(program, context: context)
                Haptics.warning()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("«\(program.name)» и её дни будут удалены. История тренировок останется.")
        }
        .alert(
            "Есть незавершённая тренировка",
            isPresented: $showingConflictAlert
        ) {
            Button("Продолжить старую") {
                guard let target = conflictSession else { return }
                clearConflict()
                openWorkout(target)
            }
            Button("Удалить и начать новую", role: .destructive) {
                let day = pendingDay
                let target = conflictSession
                clearConflict()
                if let day, let target {
                    SessionFactory.discard(target, context: context)
                    beginWorkout(day)
                }
            }
            Button("Отмена", role: .cancel) {
                clearConflict()
            }
        } message: {
            Text("«\(conflictTitle)» ещё не завершена. Если начать другой день, её прогресс будет удалён.")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if program.isActive {
                    TagPill(text: "Активна", fill: Theme.red)
                } else {
                    TagPill(text: "Не активна", color: Theme.secondary)
                }
                Spacer()
                Text(program.source == "generated" ? "ПО ПАРАМЕТРАМ" : "ВРУЧНУЮ")
                    .font(ByFont.micro)
                    .tracking(0.8)
                    .foregroundStyle(Theme.tertiary)
            }

            Text(program.name)
                .font(ByFont.display(31))
                .tracking(-1)
                .foregroundStyle(Theme.text)

            HStack(spacing: 8) {
                meta("\(program.days.count)", Formatters.plural(program.days.count, one: "день", few: "дня", many: "дней"))
                meta("\(program.totalExercises)", Formatters.plural(program.totalExercises, one: "упражнение", few: "упражнения", many: "упражнений"))
                meta("~\(program.estimatedMinutes)", Formatters.plural(program.estimatedMinutes, one: "минута", few: "минуты", many: "минут"))
            }

            if !program.trainingWeekdays.isEmpty {
                HStack(spacing: 5) {
                    ForEach(program.trainingWeekdays, id: \.self) { weekday in
                        Text(Formatters.weekdayShort(weekday))
                            .font(ByFont.micro)
                            .foregroundStyle(Theme.text)
                            .frame(width: 30, height: 24)
                            .background(Color.white.opacity(0.07), in: Capsule())
                    }
                }
            }

            HStack(spacing: 10) {
                if !program.isActive {
                    Button {
                        ProgramStore.activate(program, context: context)
                        Haptics.impact()
                    } label: {
                        Text("Сделать активной")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Button {
                    showingEditor = true
                    Haptics.tap()
                } label: {
                    Text("Изменить")
                }
                .buttonStyle(GhostButtonStyle())
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    private func meta(_ value: String, _ caption: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(ByFont.mono(12, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text(caption)
                .font(ByFont.regular(10))
                .foregroundStyle(Theme.tertiary)
        }
    }

    private func dayCard(_ day: ProgramDay) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Formatters.weekdayShort(day.weekday))
                        .font(ByFont.label)
                        .tracking(1.1)
                        .foregroundStyle(Theme.red)
                    Text(day.title)
                        .font(ByFont.heavy(21))
                        .foregroundStyle(Theme.text)
                    Text("\(Formatters.exercises(day.exercises.count)) · \(Formatters.sets(day.totalSets)) · ~\(day.estimatedMinutes) мин")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                }

                Spacer(minLength: 8)

                Button {
                    start(day)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 42, height: 42)
                        .background(Theme.redGradient, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(day.exercises.isEmpty)
                .opacity(day.exercises.isEmpty ? 0.3 : 1)
                .accessibilityLabel(
                    day.exercises.isEmpty
                        ? "В дне \(day.title) нет упражнений"
                        : "Начать \(day.title)"
                )
            }

            if day.exercises.isEmpty {
                Text("Добавь упражнения в редакторе.")
                    .font(ByFont.regular(12))
                    .foregroundStyle(Theme.tertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(day.orderedExercises.enumerated()), id: \.offset) { index, exercise in
                        exerciseRow(exercise, index: index)
                        if index < day.exercises.count - 1 {
                            ByDivider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    private func exerciseRow(_ exercise: ProgramExercise, index: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text("\(index + 1)")
                .font(ByFont.mono(10, weight: .medium))
                .foregroundStyle(Theme.tertiary)
                .frame(width: 18, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(ByFont.semibold(13))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text("\(exercise.muscle) · отдых \(exercise.restSeconds) с")
                    .font(ByFont.regular(10))
                    .foregroundStyle(Theme.tertiary)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(exercise.sets) × \(exercise.repsLabel)")
                    .font(ByFont.mono(11, weight: .semibold))
                    .foregroundStyle(Theme.text)
                if let weight = exercise.targetWeightKg {
                    Text("старт \(Formatters.number(weight)) кг")
                        .font(ByFont.regular(9.5))
                        .foregroundStyle(Theme.tertiary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func start(_ day: ProgramDay) {
        guard !day.exercises.isEmpty else {
            Haptics.warning()
            return
        }

        if let unfinished = SessionFactory.resumableSession(context: context) {
            guard unfinished.title == day.title,
                  unfinished.programName == program.name else {
                pendingDay = day
                conflictSession = unfinished
                conflictTitle = unfinished.title
                showingConflictAlert = true
                Haptics.tap()
                return
            }
            openWorkout(unfinished)
            return
        }

        beginWorkout(day)
    }

    private func beginWorkout(_ day: ProgramDay) {
        let session = SessionFactory.makeSession(
            day: day,
            program: program,
            context: context
        )
        openWorkout(session)
    }

    private func openWorkout(_ session: WorkoutSession) {
        workoutSession = session
        showingWorkout = true
        Haptics.heavy()
    }

    private func clearConflict() {
        pendingDay = nil
        conflictSession = nil
        conflictTitle = ""
    }
}
