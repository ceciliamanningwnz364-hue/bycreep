import SwiftUI
import SwiftData

struct SessionHistorySection: View {
    let sessions: [WorkoutSession]

    @State private var selectedSession: WorkoutSession?
    @State private var showingDetail = false

    private var groups: [SessionMonthGroup] {
        let grouped = Dictionary(grouping: sessions, by: { WeekClock.monthKey($0.date) })
        return grouped.compactMap { key, value in
            guard let firstDate = value.first?.date else { return nil }
            return SessionMonthGroup(
                key: key,
                title: Formatters.monthYearTitle(firstDate),
                sessions: value.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "История",
                subtitle: sessions.isEmpty
                    ? "Закрытые тренировки появятся здесь"
                    : Formatters.workouts(sessions.count)
            )

            if sessions.isEmpty {
                EmptyStateView(
                    symbol: "clock.arrow.circlepath",
                    title: "Пока тихо",
                    message: "Начни тренировку на главном экране — после завершения она попадёт в историю."
                )
                .byCard()
            } else {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 9) {
                        Text(group.title.uppercased())
                            .font(ByFont.label)
                            .tracking(1.1)
                            .foregroundStyle(Theme.secondary)
                            .padding(.horizontal, 2)

                        VStack(spacing: 0) {
                            ForEach(group.sessions, id: \.id) { session in
                                sessionRow(session)
                                if session.id != group.sessions.last?.id {
                                    ByDivider()
                                }
                            }
                        }
                        .byCard(padding: 0)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let selectedSession {
                SessionDetailView(session: selectedSession)
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        Button {
            selectedSession = session
            showingDetail = true
            Haptics.tap()
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 1) {
                    Text("\(WeekClock.calendar.component(.day, from: session.date))")
                        .font(ByFont.heavy(17))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                    Text(Formatters.weekdayShort(WeekClock.weekdayIndex(for: session.date)))
                        .font(ByFont.micro)
                        .tracking(0.4)
                        .foregroundStyle(Theme.tertiary)
                }
                .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(ByFont.semibold(14))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text("\(session.programName) · \(Formatters.sets(session.completedSets))")
                        .font(ByFont.regular(10.5))
                        .foregroundStyle(Theme.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(session.durationLabel)
                        .font(ByFont.mono(10.5, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                    Text(Formatters.volume(session.totalVolume))
                        .font(ByFont.regular(9.5))
                        .foregroundStyle(Theme.tertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SessionMonthGroup: Identifiable {
    let key: String
    let title: String
    let sessions: [WorkoutSession]
    var id: String { key }
}

// MARK: - Detail

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard

                    SectionHeader(title: "Упражнения")

                    ForEach(session.orderedExercises, id: \.id) { exercise in
                        exerciseCard(exercise)
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Удалить из истории")
                            .font(ByFont.semibold(13))
                            .foregroundStyle(Theme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .navigationTitle("Тренировка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(ByFont.semibold(13))
                    .foregroundStyle(Theme.text)
                }
            }
            .alert("Удалить тренировку?", isPresented: $showingDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    deleteSession()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Запись исчезнет из истории и прогресса недели.")
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                TagPill(text: "Закрыта")
                Spacer()
                Text(Formatters.fullDate(session.date))
                    .font(ByFont.regular(10.5))
                    .foregroundStyle(Theme.tertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(ByFont.display(28))
                    .foregroundStyle(Theme.text)
                Text(session.programName)
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.secondary)
            }

            HStack(spacing: 0) {
                metric(session.durationLabel, "Время")
                divider
                metric("\(session.completedSets)/\(session.totalSets)", "Подходы")
                divider
                metric(Formatters.volume(session.totalVolume), "Объём")
            }
        }
        .byCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(width: 1, height: 28)
    }

    private func metric(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(ByFont.heavy(16))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption.uppercased())
                .font(ByFont.micro)
                .tracking(0.5)
                .foregroundStyle(Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    private func exerciseCard(_ exercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.name)
                    .font(ByFont.semibold(15))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Spacer(minLength: 6)
                Text("\(exercise.sets.filter(\.isCompleted).count)/\(exercise.sets.count)")
                    .font(ByFont.mono(10, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
            }

            Text("\(exercise.muscle) · отдых \(exercise.restSeconds) с")
                .font(ByFont.regular(10))
                .foregroundStyle(Theme.tertiary)

            VStack(spacing: 0) {
                ForEach(Array(exercise.orderedSets.enumerated()), id: \.offset) { index, set in
                    HStack(spacing: 9) {
                        Text("\(index + 1)")
                            .font(ByFont.mono(10, weight: .medium))
                            .foregroundStyle(Theme.tertiary)
                            .frame(width: 16, alignment: .leading)

                        Text(set.weightKg > 0 ? Formatters.kg(set.weightKg) : "свой вес")
                            .font(ByFont.mono(11, weight: .medium))
                            .foregroundStyle(set.isCompleted ? Theme.text : Theme.tertiary)
                            .frame(minWidth: 68, alignment: .leading)

                        Text("× \(set.reps)")
                            .font(ByFont.mono(11, weight: .medium))
                            .foregroundStyle(set.isCompleted ? Theme.secondary : Theme.tertiary)

                        Spacer()

                        Image(systemName: set.isCompleted ? "checkmark" : "minus")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(set.isCompleted ? Theme.red : Theme.tertiary)
                    }
                    .padding(.vertical, 6)
                    .opacity(set.isCompleted ? 1 : 0.5)

                    if index < exercise.sets.count - 1 {
                        ByDivider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard(padding: 14, radius: 18)
    }

    private func deleteSession() {
        context.delete(session)
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.warning()
        dismiss()
    }
}
