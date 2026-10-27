import SwiftUI
import SwiftData
import UIKit

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var session: WorkoutSession

    @State private var restEnd: Date?
    @State private var restTotal: TimeInterval = 0
    @State private var showingExitDialog = false
    @State private var showingFinishDialog = false
    @State private var didDiscard = false
    @State private var refreshToken = 0

    private var progress: Double {
        session.totalSets > 0
            ? Double(session.completedSets) / Double(session.totalSets)
            : 0
    }

    var body: some View {
        let _ = refreshToken
        NavigationStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(session.orderedExercises, id: \.id) { exercise in
                            exerciseCard(exercise)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(ByBackground())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                restInset
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        dismissKeyboard()
                    }
                    .foregroundStyle(Theme.text)
                }
            }
        }
        .confirmationDialog(
            "Завершить тренировку?",
            isPresented: $showingFinishDialog,
            titleVisibility: .visible
        ) {
            Button("Завершить") {
                finishSession()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            if session.completedSets == 0 {
                Text("Ни один подход не отмечен. Всё равно завершить?")
            } else {
                Text("\(Formatters.sets(session.completedSets)) из \(session.totalSets) · \(Formatters.volume(session.totalVolume))")
            }
        }
        .confirmationDialog(
            "Выйти из тренировки?",
            isPresented: $showingExitDialog,
            titleVisibility: .visible
        ) {
            Button("Продолжить позже") {
                SessionFactory.pause(session, context: context)
                dismiss()
            }
            Button("Удалить тренировку", role: .destructive) {
                didDiscard = true
                SessionFactory.discard(session, context: context)
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Прогресс сохранится. Вернуться можно с главного экрана.")
        }
        .task(id: restEnd) {
            guard let end = restEnd else { return }
            let interval = end.timeIntervalSinceNow
            if interval > 0 {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            if let currentEnd = restEnd, Date() >= currentEnd {
                restEnd = nil
                Haptics.success()
            }
        }
        .onAppear {
            SessionFactory.resume(session, context: context)
        }
        .onChange(of: scenePhase) { _, phase in
            guard !didDiscard, !session.isCompleted else { return }
            switch phase {
            case .active:
                SessionFactory.resume(session, context: context)
            case .inactive, .background:
                SessionFactory.pause(session, context: context)
            @unknown default:
                break
            }
        }
        .onDisappear {
            if !didDiscard && !session.isCompleted {
                SessionFactory.pause(session, context: context)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    showingExitDialog = true
                    Haptics.tap()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .frame(width: 38, height: 38)
                        .background(Theme.surfaceElevated, in: Circle())
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Свернуть тренировку")

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.red)
                        .frame(width: 5, height: 5)
                    Text("В РАБОТЕ")
                        .font(ByFont.label)
                        .tracking(1.4)
                        .foregroundStyle(Theme.red)
                }

                Spacer()

                Button {
                    showingFinishDialog = true
                    Haptics.tap()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Theme.text)
                        .frame(width: 38, height: 38)
                        .background(Theme.redGradient, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Завершить тренировку")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(ByFont.display(30))
                    .tracking(-0.8)
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(session.programName.uppercased())
                    .font(ByFont.micro)
                    .tracking(1)
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 0) {
                elapsedMetric
                Rectangle()
                    .fill(Theme.stroke)
                    .frame(width: 1, height: 28)
                headerMetric(
                    value: "\(session.completedSets)/\(session.totalSets)",
                    title: "Подходы",
                    symbol: "checkmark.circle"
                )
                Rectangle()
                    .fill(Theme.stroke)
                    .frame(width: 1, height: 28)
                headerMetric(
                    value: Formatters.volume(session.totalVolume),
                    title: "Объём",
                    symbol: "scalemass"
                )
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(Theme.red)
                        .frame(width: max(proxy.size.width * progress, progress > 0 ? 5 : 0))
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var elapsedMetric: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(Formatters.timer(session.elapsedSeconds(at: timeline.date)))
                        .font(ByFont.mono(13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            Text("ВРЕМЯ")
                .font(ByFont.micro)
                .tracking(0.5)
                .foregroundStyle(Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    private func headerMetric(value: String, title: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text(value)
                    .font(ByFont.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(title.uppercased())
                .font(ByFont.micro)
                .tracking(0.5)
                .foregroundStyle(Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    // MARK: Exercise cards

    private func exerciseCard(_ exercise: SessionExercise) -> some View {
        let completed = exercise.sets.filter(\.isCompleted).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(ByFont.heavy(18))
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                    Text("\(exercise.muscle) · отдых \(exercise.restSeconds) с")
                        .font(ByFont.regular(10.5))
                        .foregroundStyle(Theme.tertiary)
                    if !exercise.note.isEmpty {
                        Text(exercise.note)
                            .font(ByFont.regular(10.5))
                            .foregroundStyle(Theme.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(completed)/\(exercise.sets.count)")
                        .font(ByFont.mono(14, weight: .semibold))
                        .foregroundStyle(completed == exercise.sets.count ? Theme.red : Theme.text)
                    Text("ПОДХОДЫ")
                        .font(ByFont.micro)
                        .tracking(0.5)
                        .foregroundStyle(Theme.tertiary)
                }
            }

            VStack(spacing: 7) {
                ForEach(Array(exercise.orderedSets.enumerated()), id: \.offset) { index, set in
                    WorkoutSetRow(set: set, index: index) { isCompleted in
                        handleSetToggle(isCompleted, exercise: exercise)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSet(set, from: exercise)
                        } label: {
                            Label("Удалить подход", systemImage: "trash")
                        }
                    }
                }
            }

            Button {
                addSet(to: exercise)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .black))
                    Text("ДОБАВИТЬ ПОДХОД")
                        .font(ByFont.micro)
                        .tracking(0.6)
                }
                .foregroundStyle(Theme.secondary)
                .padding(.vertical, 7)
                .padding(.horizontal, 11)
                .background(Color.white.opacity(0.04), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    // MARK: Rest

    @ViewBuilder
    private var restInset: some View {
        if let end = restEnd, end > Date() {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let remaining = max(0, Int(ceil(end.timeIntervalSince(timeline.date))))
                let ratio = restTotal > 0
                    ? max(0, min(1, end.timeIntervalSince(timeline.date) / restTotal))
                    : 0

                VStack(spacing: 9) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.red)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("ОТДЫХ")
                                .font(ByFont.micro)
                                .tracking(1)
                                .foregroundStyle(Theme.secondary)
                            Text(Formatters.timer(remaining))
                                .font(ByFont.mono(19, weight: .semibold))
                                .foregroundStyle(Theme.text)
                                .monospacedDigit()
                        }

                        Spacer()

                        Button {
                            restEnd = nil
                            Haptics.tap()
                        } label: {
                            Text("Пропустить")
                                .font(ByFont.semibold(12))
                                .foregroundStyle(Theme.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.06), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.07))
                            Capsule()
                                .fill(Theme.red)
                                .frame(width: proxy.size.width * ratio)
                        }
                    }
                    .frame(height: 3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Theme.bg)
            }
        }
    }

    // MARK: Actions

    private func handleSetToggle(_ isCompleted: Bool, exercise: SessionExercise) {
        if isCompleted {
            let seconds = max(exercise.restSeconds, 0)
            if seconds > 0 {
                restTotal = TimeInterval(seconds)
                restEnd = Date().addingTimeInterval(restTotal)
            }
            Haptics.impact()
        } else {
            Haptics.tap()
        }
        refreshToken += 1
        ProgramStore.save(context)
    }

    private func addSet(to exercise: SessionExercise) {
        let last = exercise.orderedSets.last
        let newSet = SetEntry(
            order: (last?.order ?? -1) + 1,
            reps: last?.reps ?? 8,
            weightKg: last?.weightKg ?? 0
        )
        context.insert(newSet)
        exercise.sets.append(newSet)
        refreshToken += 1
        ProgramStore.save(context)
        Haptics.tap()
    }

    private func deleteSet(_ set: SetEntry, from exercise: SessionExercise) {
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        refreshToken += 1
        ProgramStore.save(context)
        Haptics.warning()
    }

    private func finishSession() {
        SessionFactory.finish(session, context: context)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Set row

private struct WorkoutSetRow: View {
    @Bindable var set: SetEntry
    let index: Int
    let onToggle: (Bool) -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case weight, reps
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("\(index + 1)")
                .font(ByFont.mono(10, weight: .medium))
                .foregroundStyle(set.isCompleted ? Theme.red : Theme.tertiary)
                .frame(width: 18)

            HStack(spacing: 4) {
                TextField(
                    "0",
                    value: $set.weightKg,
                    format: .number.precision(.fractionLength(0...1))
                )
                .focused($focusedField, equals: .weight)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(ByFont.mono(14, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .monospacedDigit()

                Text("кг")
                    .font(ByFont.regular(10))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.horizontal, 9)
            .frame(height: 40)
            .background(fieldFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(fieldStroke, lineWidth: 1)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 3) {
                TextField(
                    "0",
                    value: $set.reps,
                    format: .number
                )
                .focused($focusedField, equals: .reps)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(ByFont.mono(14, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .monospacedDigit()

                Text("повт")
                    .font(ByFont.regular(9))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.horizontal, 8)
            .frame(width: 86, height: 40)
            .background(fieldFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(fieldStroke, lineWidth: 1)
            }

            Button {
                set.isCompleted.toggle()
                focusedField = nil
                onToggle(set.isCompleted)
            } label: {
                ZStack {
                    if set.isCompleted {
                        Circle().fill(Theme.red)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Theme.text)
                    } else {
                        Circle().strokeBorder(Theme.strokeStrong, lineWidth: 1)
                    }
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "Отметить подход невыполненным" : "Отметить подход выполненным")
        }
        .opacity(set.isCompleted ? 0.82 : 1)
    }

    private var fieldFill: Color {
        set.isCompleted ? Theme.red.opacity(0.08) : Theme.surfaceSoft
    }

    private var fieldStroke: Color {
        set.isCompleted ? Theme.red.opacity(0.24) : Theme.stroke
    }
}

// MARK: - Helpers

private func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
