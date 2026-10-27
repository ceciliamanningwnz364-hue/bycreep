import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Bindable var profile: UserProfile

    @Query(sort: \ProgressPhoto.date, order: .reverse)
    private var photos: [ProgressPhoto]

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var tab = 0

    private var completedSessions: [WorkoutSession] {
        sessions.filter(\.isCompleted)
    }

    private var latestWeight: Double {
        measurements.first?.weightKg ?? profile.weightKg
    }

    private var weightChange: Double? {
        guard let first = measurements.last, measurements.count > 1 else {
            return nil
        }
        return latestWeight - first.weightKg
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle(eyebrow: "03 · Динамика", title: "Прогресс")
                summaryCard
                SegmentBar(
                    titles: ["Фото", "Замеры", "История"],
                    selection: $tab
                )

                switch tab {
                case 0:
                    ProgressPhotosSection(
                        photos: photos,
                        initialWeight: latestWeight
                    )
                case 1:
                    MeasurementsSection(
                        measurements: measurements,
                        profile: profile
                    )
                default:
                    SessionHistorySection(sessions: completedSessions)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(ByBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryMetric(
                value: Formatters.kg(latestWeight),
                label: "Сейчас",
                symbol: "scalemass"
            )
            summaryDivider
            summaryMetric(
                value: weightChangeValue,
                label: "Динамика",
                symbol: weightChangeSymbol
            )
            summaryDivider
            summaryMetric(
                value: "\(photos.count)",
                label: "Фото",
                symbol: "photo.stack"
            )
            summaryDivider
            summaryMetric(
                value: "\(completedSessions.count)",
                label: "Тренировок",
                symbol: "checkmark.seal"
            )
        }
        .byCard(padding: 14, radius: 20)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(width: 1, height: 34)
    }

    private var weightChangeValue: String {
        guard let change = weightChange else { return "—" }
        guard abs(change) >= 0.05 else { return "0" }
        let sign = change > 0 ? "+" : "−"
        return "\(sign)\(Formatters.number(abs(change)))"
    }

    private var weightChangeSymbol: String {
        guard let change = weightChange, abs(change) >= 0.05 else {
            return "arrow.right"
        }
        return change > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private func summaryMetric(value: String, label: String, symbol: String) -> some View {
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
            Text(label.uppercased())
                .font(ByFont.micro)
                .tracking(0.4)
                .foregroundStyle(Theme.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
    }
}
