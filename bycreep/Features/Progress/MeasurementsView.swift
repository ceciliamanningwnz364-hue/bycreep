import SwiftUI
import SwiftData

struct MeasurementsSection: View {
    @Environment(\.modelContext) private var context

    let measurements: [BodyMeasurement]
    let profile: UserProfile

    @State private var showingAdd = false
    @State private var measurementToDelete: BodyMeasurement?
    @State private var showingDeleteAlert = false

    private var latest: BodyMeasurement? { measurements.first }

    private var previous: BodyMeasurement? {
        measurements.count > 1 ? measurements[1] : nil
    }

    private var chronological: [BodyMeasurement] {
        measurements.sorted { $0.date < $1.date }
    }

    private var chartValues: [Double] {
        Array(chronological.suffix(30)).map(\.weightKg)
    }

    private var delta: Double? {
        guard let latest, let previous else { return nil }
        return latest.weightKg - previous.weightKg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Вес",
                subtitle: "Утро, после туалета, до еды — максимально честно"
            )

            weightCard

            HStack(alignment: .center, spacing: 10) {
                SectionHeader(title: "Замеры", subtitle: "\(measurements.count) записей")
                Button {
                    showingAdd = true
                    Haptics.tap()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.bg)
                        .frame(width: 38, height: 38)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Добавить замер")
            }

            if measurements.isEmpty {
                EmptyStateView(
                    symbol: "ruler",
                    title: "Пока нет замеров",
                    message: "Добавь вес и обхваты — приложение покажет динамику.",
                    actionTitle: "Добавить замер",
                    action: { showingAdd = true }
                )
                .byCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(measurements, id: \.id) { measurement in
                        measurementRow(measurement)
                        if measurement.id != measurements.last?.id {
                            ByDivider()
                        }
                    }
                }
                .byCard(padding: 0)
            }

            Button {
                showingAdd = true
                Haptics.tap()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .black))
                    Text("Добавить замер")
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
        .sheet(isPresented: $showingAdd) {
            AddMeasurementView(
                profile: profile,
                latestDate: latest?.date,
                initialWeight: latest?.weightKg ?? profile.weightKg
            )
        }
        .alert(
            "Удалить замер?",
            isPresented: $showingDeleteAlert,
            presenting: measurementToDelete
        ) { measurement in
            Button("Удалить", role: .destructive) {
                delete(measurement)
            }
            Button("Отмена", role: .cancel) {}
        } message: { _ in
            Text("Запись исчезнет из графика и истории замеров.")
        }
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("СЕЙЧАС")
                        .font(ByFont.micro)
                        .tracking(0.9)
                        .foregroundStyle(Theme.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(Formatters.number(latest?.weightKg ?? profile.weightKg))
                            .font(ByFont.display(34))
                            .foregroundStyle(Theme.text)
                            .monospacedDigit()
                        Text("кг")
                            .font(ByFont.regular(12))
                            .foregroundStyle(Theme.tertiary)
                    }
                }

                Spacer()

                if let delta {
                    deltaPill(delta)
                }
            }

            if chartValues.count > 1 {
                WeightChart(values: chartValues)
                    .frame(height: 120)
                    .padding(.top, 2)

                HStack {
                    Text(Formatters.shortDate(chronological.first?.date ?? Date()))
                    Spacer()
                    Text(Formatters.shortDate(chronological.last?.date ?? Date()))
                }
                .font(ByFont.regular(9.5))
                .foregroundStyle(Theme.tertiary)
            } else {
                Text("Добавь ещё один замер — появится график динамики.")
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .padding(.vertical, 6)
            }

            if let bmi = latest.map({ $0.weightKg / pow(profile.heightCm / 100, 2) }) {
                HStack(spacing: 6) {
                    Text("ИМТ")
                        .font(ByFont.micro)
                        .tracking(0.5)
                        .foregroundStyle(Theme.tertiary)
                    Text(Formatters.number(bmi, maxFraction: 1))
                        .font(ByFont.mono(10, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                    Text("· \(NutritionCalculator.bmiCategory(bmi))")
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.tertiary)
                    Spacer()
                }
            }
        }
        .byCard()
    }

    private func deltaPill(_ value: Double) -> some View {
        let isZero = abs(value) < 0.05
        let symbol = value > 0 ? "arrow.up.right" : "arrow.down.right"
        return HStack(spacing: 4) {
            if !isZero {
                Image(systemName: symbol)
                    .font(.system(size: 8, weight: .bold))
            }
            Text(
                isZero
                    ? "0 кг"
                    : "\(value > 0 ? "+" : "−")\(Formatters.number(abs(value))) кг"
            )
            .font(ByFont.mono(10, weight: .semibold))
        }
        .foregroundStyle(isZero ? Theme.tertiary : Theme.red)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Theme.redSoft, in: Capsule())
    }

    private func measurementRow(_ measurement: BodyMeasurement) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 1) {
                Text("\(WeekClock.calendar.component(.day, from: measurement.date))")
                    .font(ByFont.heavy(17))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                Text(Formatters.weekdayShort(WeekClock.weekdayIndex(for: measurement.date)))
                    .font(ByFont.micro)
                    .tracking(0.4)
                    .foregroundStyle(Theme.tertiary)
            }
            .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(Formatters.kg(measurement.weightKg))
                        .font(ByFont.heavy(17))
                        .foregroundStyle(Theme.text)
                    if let bodyFat = measurement.bodyFat {
                        Text("· \(Formatters.number(bodyFat))% жира")
                            .font(ByFont.regular(10))
                            .foregroundStyle(Theme.tertiary)
                    }
                }

                if !detailLine(measurement).isEmpty {
                    Text(detailLine(measurement))
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if !measurement.note.isEmpty {
                    Text(measurement.note)
                        .font(ByFont.regular(10))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 6)

            Menu {
                Button(role: .destructive) {
                    measurementToDelete = measurement
                    showingDeleteAlert = true
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
                    .frame(width: 28, height: 36)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func detailLine(_ measurement: BodyMeasurement) -> String {
        var parts: [String] = []
        if let chest = measurement.chestCm { parts.append("грудь \(Formatters.number(chest))") }
        if let waist = measurement.waistCm { parts.append("талия \(Formatters.number(waist))") }
        if let hips = measurement.hipsCm { parts.append("бёдра \(Formatters.number(hips))") }
        if let arm = measurement.armCm { parts.append("рука \(Formatters.number(arm))") }
        if let thigh = measurement.thighCm { parts.append("бедро \(Formatters.number(thigh))") }
        return parts.joined(separator: " · ")
    }

    private func delete(_ measurement: BodyMeasurement) {
        let deletedID = measurement.id
        let wasLatest = measurements.first?.id == deletedID
        context.delete(measurement)
        ProgramStore.save(context)

        if wasLatest {
            let nextLatest = measurements.first { $0.id != deletedID }
            if let nextLatest {
                profile.weightKg = nextLatest.weightKg
                ProgramStore.save(context)
            }
        }

        Haptics.warning()
    }
}

// MARK: - Add measurement

private struct AddMeasurementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile
    let latestDate: Date?

    @State private var date = Date()
    @State private var weightText: String
    @State private var bodyFatText = ""
    @State private var chestText = ""
    @State private var waistText = ""
    @State private var hipsText = ""
    @State private var armText = ""
    @State private var thighText = ""
    @State private var note = ""

    init(profile: UserProfile, latestDate: Date?, initialWeight: Double) {
        self.profile = profile
        self.latestDate = latestDate
        _weightText = State(
            initialValue: initialWeight > 0 ? Formatters.number(initialWeight) : ""
        )
    }

    private var weightValue: Double? {
        parse(weightText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    weightCard
                    dateCard
                    circumferenceCard
                    noteCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .background(ByBackground())
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle("Замер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("НОВЫЙ ЗАМЕР")
                .font(ByFont.label)
                .tracking(1.4)
                .foregroundStyle(Theme.red)
            Text("Цифры не врут")
                .font(ByFont.display(30))
                .tracking(-0.8)
                .foregroundStyle(Theme.text)
            Text("Вес обязателен, обхваты — по желанию. Смотри на тренд, а не на один день.")
                .font(ByFont.regular(12))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(2)
        }
        .padding(.top, 4)
    }

    private var weightCard: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            TextField("0", text: $weightText)
                .font(ByFont.display(44))
                .foregroundStyle(Theme.text)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("кг")
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.tertiary)
        }
        .byCard()
    }

    private var dateCard: some View {
        HStack {
            Label("Дата", systemImage: "calendar")
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .tint(Theme.red)
        }
        .byCard()
    }

    private var circumferenceCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("ОБХВАТЫ, СМ")
                .font(ByFont.label)
                .tracking(1.1)
                .foregroundStyle(Theme.secondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 9),
                    GridItem(.flexible(), spacing: 9)
                ],
                spacing: 9
            ) {
                metricInput("Грудь", text: $chestText, suffix: "см")
                metricInput("Талия", text: $waistText, suffix: "см")
                metricInput("Бёдра", text: $hipsText, suffix: "см")
                metricInput("Рука", text: $armText, suffix: "см")
                metricInput("Бедро", text: $thighText, suffix: "см")
                metricInput("Жир", text: $bodyFatText, suffix: "%")
            }
        }
        .byCard()
    }

    private func metricInput(_ title: String, text: Binding<String>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(ByFont.regular(10.5))
                .foregroundStyle(Theme.tertiary)
            HStack(spacing: 4) {
                TextField("—", text: text)
                    .font(ByFont.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                Text(suffix)
                    .font(ByFont.regular(9))
                    .foregroundStyle(Theme.tertiary)
            }
            .byField(minHeight: 42)
        }
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ЗАМЕТКА")
                .font(ByFont.label)
                .tracking(1.1)
                .foregroundStyle(Theme.secondary)
            TextField("Самочувствие, сон, питание…", text: $note, axis: .vertical)
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.text)
                .lineLimit(2...4)
                .byField(minHeight: 70)
        }
        .byCard()
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            Text("Сохранить замер")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(weightValue == nil)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.bg)
    }

    private func parse(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty, let value = Double(cleaned), value > 0 else {
            return nil
        }
        return value
    }

    private func save() {
        guard let weight = weightValue else { return }

        let measurement = BodyMeasurement(
            date: date,
            weightKg: weight,
            bodyFat: parse(bodyFatText),
            chestCm: parse(chestText),
            waistCm: parse(waistText),
            hipsCm: parse(hipsText),
            armCm: parse(armText),
            thighCm: parse(thighText),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(measurement)

        if latestDate == nil || date >= latestDate! {
            profile.weightKg = weight
        }

        ProgramStore.save(context)
        Haptics.success()
        dismiss()
    }
}
