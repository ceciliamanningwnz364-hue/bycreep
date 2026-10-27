import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var program: Program

    @State private var selectedDay: ProgramDay?
    @State private var editingExercise: ProgramExercise?
    @State private var showingExerciseEditor = false
    @State private var dayToDelete: ProgramDay?
    @State private var showingDayDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    programHeader
                    daysHeader

                    ForEach(program.orderedDays, id: \.id) { day in
                        dayEditorCard(day)
                    }

                    if canAddDay {
                        Button {
                            addDay()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .black))
                                Text("Добавить день")
                            }
                        }
                        .buttonStyle(GhostButtonStyle())
                    } else {
                        Text("Все 7 дней недели заняты. Чтобы добавить другой день, сначала измени день недели у одного из существующих.")
                            .font(ByFont.regular(11))
                            .foregroundStyle(Theme.tertiary)
                            .lineSpacing(2)
                            .padding(.horizontal, 4)
                    }

                    Text("Совет: не ставь два тяжёлых дня подряд на одну и ту же группу мышц. Оставляй 1–2 повторения в запасе.")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                        .lineSpacing(2)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .navigationTitle("Редактор")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        saveAndClose()
                    }
                    .font(ByFont.semibold(14))
                    .foregroundStyle(Theme.text)
                }
            }
            .sheet(isPresented: $showingExerciseEditor) {
                if let selectedDay {
                    ExerciseEditorSheet(
                        day: selectedDay,
                        exercise: editingExercise
                    )
                }
            }
            .alert("Удалить день?", isPresented: $showingDayDeleteAlert, presenting: dayToDelete) { day in
                Button("Удалить", role: .destructive) {
                    deleteDay(day)
                }
                Button("Отмена", role: .cancel) {}
            } message: { day in
                Text("«\(day.title)» и его упражнения будут удалены.")
            }
        }
        .onDisappear {
            ProgramStore.save(context)
            WidgetBridge.refresh(context: context)
        }
    }

    private var programHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("НАЗВАНИЕ")
                .font(ByFont.label)
                .tracking(1.2)
                .foregroundStyle(Theme.red)

            TextField("Название программы", text: $program.name)
                .font(ByFont.display(27))
                .tracking(-0.6)
                .foregroundStyle(Theme.text)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .padding(.vertical, 2)

            ByDivider()

            Toggle(isOn: activeBinding) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Активная программа")
                        .font(ByFont.semibold(14))
                        .foregroundStyle(Theme.text)
                    Text("Задаёт расписание, виджет и тренировку дня")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                }
            }
            .tint(Theme.red)

            Text("\(Formatters.days(program.days.count)) · \(Formatters.exercises(program.totalExercises))")
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    private var activeBinding: Binding<Bool> {
        Binding(
            get: { program.isActive },
            set: { newValue in
                if newValue {
                    ProgramStore.activate(program, context: context)
                } else {
                    program.isActive = false
                    ProgramStore.save(context)
                    WidgetBridge.refresh(context: context)
                }
            }
        )
    }

    private var canAddDay: Bool {
        program.days.count < 7
    }

    private var daysHeader: some View {
        HStack {
            SectionHeader(
                title: "Дни программы",
                subtitle: "Отредактируй название, день недели и упражнения"
            )
            Spacer()
            Button {
                addDay()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 36, height: 36)
                    .background(Theme.surfaceElevated, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canAddDay)
            .opacity(canAddDay ? 1 : 0.3)
            .accessibilityLabel("Добавить день")
        }
    }

    private func dayEditorCard(_ day: ProgramDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(1...7, id: \.self) { weekday in
                        Button {
                            selectWeekday(weekday, for: day)
                        } label: {
                            if weekday == day.weekday {
                                Label(WeekClock.fullLabels[weekday - 1], systemImage: "checkmark")
                            } else if occupiedDay(excluding: day, weekday: weekday) != nil {
                                Label(
                                    "\(WeekClock.fullLabels[weekday - 1]) · обменять",
                                    systemImage: "arrow.left.arrow.right"
                                )
                            } else {
                                Text(WeekClock.fullLabels[weekday - 1])
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(Formatters.weekdayShort(day.weekday))
                            .font(ByFont.label)
                            .tracking(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .bold))
                    }
                    .foregroundStyle(Theme.red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Theme.redSoft, in: Capsule())
                }

                TextField(
                    "Название дня",
                    text: Binding(
                        get: { day.title },
                        set: { day.title = $0 }
                    )
                )
                    .font(ByFont.heavy(18))
                    .foregroundStyle(Theme.text)
                    .textInputAutocapitalization(.characters)
                    .submitLabel(.done)

                Menu {
                    Button {
                        selectedDay = day
                        editingExercise = nil
                        showingExerciseEditor = true
                    } label: {
                        Label("Добавить упражнение", systemImage: "plus")
                    }

                    Button(role: .destructive) {
                        dayToDelete = day
                        showingDayDeleteAlert = true
                    } label: {
                        Label("Удалить день", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 30, height: 34)
                }
            }

            Text("\(Formatters.exercises(day.exercises.count)) · \(Formatters.sets(day.totalSets))")
                .font(ByFont.regular(11))
                .foregroundStyle(Theme.tertiary)

            if day.exercises.isEmpty {
                Text("Добавь первое упражнение — название, подходы и диапазон повторений.")
                    .font(ByFont.regular(12))
                    .foregroundStyle(Theme.tertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(day.orderedExercises, id: \.id) { exercise in
                        exerciseEditorRow(exercise, day: day)
                        if exercise.id != day.orderedExercises.last?.id {
                            ByDivider()
                        }
                    }
                }
            }

            Button {
                selectedDay = day
                editingExercise = nil
                showingExerciseEditor = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .black))
                    Text("Добавить упражнение")
                        .font(ByFont.semibold(12))
                }
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard()
    }

    private func exerciseEditorRow(_ exercise: ProgramExercise, day: ProgramDay) -> some View {
        HStack(spacing: 8) {
            Button {
                selectedDay = day
                editingExercise = exercise
                showingExerciseEditor = true
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(ByFont.semibold(13))
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                        Text("\(exercise.muscle) · \(exercise.sets) × \(exercise.repsLabel) · \(exercise.restSeconds) с")
                            .font(ByFont.regular(10))
                            .foregroundStyle(Theme.tertiary)
                    }

                    Spacer(minLength: 6)

                    Text(exercise.targetWeightKg.map { "\(Formatters.number($0)) кг" } ?? "—")
                        .font(ByFont.mono(10, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    selectedDay = day
                    editingExercise = exercise
                    showingExerciseEditor = true
                } label: {
                    Label("Изменить", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteExercise(exercise)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 24, height: 36)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 8)
    }

    private func occupiedDay(excluding day: ProgramDay, weekday: Int) -> ProgramDay? {
        program.days.first { $0.id != day.id && $0.weekday == weekday }
    }

    /// Weekdays stay unique: picking one that is already taken swaps the two days.
    private func selectWeekday(_ weekday: Int, for day: ProgramDay) {
        guard day.weekday != weekday else { return }
        if let occupant = occupiedDay(excluding: day, weekday: weekday) {
            occupant.weekday = day.weekday
        }
        day.weekday = weekday
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.tap()
    }

    private func addDay() {
        guard canAddDay else { return }

        let used = Set(program.days.map(\.weekday))
        let nextWeekday = (1...7).first(where: { !used.contains($0) })
            ?? WeekClock.weekdayIndex(for: Date())

        let day = ProgramDay(
            weekday: nextWeekday,
            title: "ДЕНЬ \(program.days.count + 1)",
            order: program.days.count
        )
        context.insert(day)
        program.days.append(day)
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.impact()
    }

    private func deleteDay(_ day: ProgramDay) {
        program.days.removeAll { $0.id == day.id }
        context.delete(day)
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.warning()
    }

    private func deleteExercise(_ exercise: ProgramExercise) {
        for day in program.days {
            day.exercises.removeAll { $0.id == exercise.id }
        }
        context.delete(exercise)
        ProgramStore.save(context)
        Haptics.warning()
    }

    private func saveAndClose() {
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Exercise editor

private struct ExerciseEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let day: ProgramDay
    let exercise: ProgramExercise?

    @State private var name: String
    @State private var muscle: String
    @State private var sets: Int
    @State private var repsLow: Int
    @State private var repsHigh: Int
    @State private var restSeconds: Int
    @State private var weightText: String
    @State private var note: String

    private let muscles = [
        "Грудь", "Спина", "Плечи", "Бицепс", "Трицепс",
        "Ноги", "Ягодицы", "Икры", "Кор", "Другое"
    ]

    init(day: ProgramDay, exercise: ProgramExercise?) {
        self.day = day
        self.exercise = exercise

        _name = State(initialValue: exercise?.name ?? "")
        _muscle = State(initialValue: exercise?.muscle ?? "Другое")
        _sets = State(initialValue: exercise?.sets ?? 3)
        _repsLow = State(initialValue: exercise?.repsLow ?? 8)
        _repsHigh = State(initialValue: exercise?.repsHigh ?? 12)
        _restSeconds = State(initialValue: exercise?.restSeconds ?? 90)
        _weightText = State(
            initialValue: exercise?.targetWeightKg.map {
                Formatters.number($0, maxFraction: 1)
            } ?? ""
        )
        _note = State(initialValue: exercise?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("УПРАЖНЕНИЕ")
                            .font(ByFont.label)
                            .tracking(1.2)
                            .foregroundStyle(Theme.red)
                        TextField("Название упражнения", text: $name)
                            .font(ByFont.heavy(24))
                            .foregroundStyle(Theme.text)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                    }
                    .byCard()

                    VStack(spacing: 0) {
                        muscleRow
                        ByDivider()
                        StepperRow(title: "Подходы", value: $sets, range: 1...10, suffix: "")
                            .padding(.vertical, 10)
                        ByDivider()
                        StepperRow(title: "Повторения от", value: $repsLow, range: 1...50, suffix: "")
                            .padding(.vertical, 10)
                        ByDivider()
                        StepperRow(title: "Повторения до", value: $repsHigh, range: 1...50, suffix: "")
                            .padding(.vertical, 10)
                        ByDivider()
                        StepperRow(
                            title: "Отдых",
                            value: $restSeconds,
                            range: 15...300,
                            step: 15,
                            suffix: "сек"
                        )
                        .padding(.vertical, 10)
                    }
                    .byCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("СТАРТОВЫЙ ВЕС")
                            .font(ByFont.label)
                            .tracking(1.1)
                            .foregroundStyle(Theme.secondary)

                        HStack(spacing: 8) {
                            TextField("Необязательно", text: $weightText)
                                .font(ByFont.heavy(20))
                                .foregroundStyle(Theme.text)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("кг")
                                .font(ByFont.regular(12))
                                .foregroundStyle(Theme.tertiary)
                        }
                        .byField()

                        Text("Можно оставить пустым — вес введёшь на тренировке.")
                            .font(ByFont.regular(10))
                            .foregroundStyle(Theme.tertiary)
                    }
                    .byCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("ЗАМЕТКА")
                            .font(ByFont.label)
                            .tracking(1.1)
                            .foregroundStyle(Theme.secondary)
                        TextField("Техника, настройки тренажёра…", text: $note, axis: .vertical)
                            .font(ByFont.regular(13))
                            .foregroundStyle(Theme.text)
                            .lineLimit(3...5)
                            .byField(minHeight: 80)
                    }
                    .byCard()

                    Text("Верх диапазона повторений — ориентир для прогрессии. Когда он стабильно получается, добавь минимальный шаг веса.")
                        .font(ByFont.regular(11))
                        .foregroundStyle(Theme.tertiary)
                        .lineSpacing(2)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 22)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom) {
                Button {
                    save()
                } label: {
                    Text(exercise == nil ? "Добавить упражнение" : "Сохранить")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(Theme.bg)
            }
            .navigationTitle(exercise == nil ? "Новое упражнение" : "Упражнение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondary)
                }
            }
        }
        .onChange(of: repsLow) { _, newValue in
            if repsHigh < newValue {
                repsHigh = newValue
            }
        }
        .onChange(of: repsHigh) { _, newValue in
            if repsLow > newValue {
                repsLow = newValue
            }
        }
    }

    private var muscleRow: some View {
        HStack {
            Text("Группа мышц")
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
            Spacer()
            Menu {
                ForEach(muscles, id: \.self) { item in
                    Button(item) {
                        muscle = item
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(muscle)
                        .font(ByFont.semibold(13))
                        .foregroundStyle(Theme.text)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(Theme.tertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.surfaceSoft, in: Capsule())
            }
        }
        .padding(.vertical, 12)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let weight = Double(
            weightText
                .replacingOccurrences(of: ",", with: ".")
                .trimmingCharacters(in: .whitespaces)
        )
        let validWeight = weight.flatMap { $0 > 0 ? $0 : nil }

        if let exercise {
            exercise.name = trimmedName
            exercise.muscle = muscle
            exercise.sets = sets
            exercise.repsLow = min(repsLow, repsHigh)
            exercise.repsHigh = max(repsLow, repsHigh)
            exercise.restSeconds = restSeconds
            exercise.targetWeightKg = validWeight
            exercise.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let newExercise = ProgramExercise(
                name: trimmedName,
                muscle: muscle,
                sets: sets,
                repsLow: min(repsLow, repsHigh),
                repsHigh: max(repsLow, repsHigh),
                restSeconds: restSeconds,
                targetWeightKg: validWeight,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                order: day.exercises.count
            )
            context.insert(newExercise)
            day.exercises.append(newExercise)
        }

        ProgramStore.save(context)
        Haptics.success()
        dismiss()
    }
}

private struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var suffix: String = ""

    var body: some View {
        HStack {
            Text(title)
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)

            Spacer()

            HStack(spacing: 10) {
                stepButton(systemName: "minus") {
                    value = max(range.lowerBound, value - step)
                    Haptics.tap()
                }

                Text("\(value)\(suffix.isEmpty ? "" : " \(suffix)")")
                    .font(ByFont.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(minWidth: 46)
                    .multilineTextAlignment(.center)

                stepButton(systemName: "plus") {
                    value = min(range.upperBound, value + step)
                    Haptics.tap()
                }
            }
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(Theme.text)
                .frame(width: 28, height: 28)
                .background(Theme.surfaceSoft, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
