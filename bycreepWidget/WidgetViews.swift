import SwiftUI
import WidgetKit

// MARK: - Palette

private enum WidgetTheme {
    static let red = Color(red: 1.0, green: 0.176, blue: 0.176)
    static let deepRed = Color(red: 0.66, green: 0.0, blue: 0.05)
    static let text = Color.white
    static let secondary = Color.white.opacity(0.58)
    static let tertiary = Color.white.opacity(0.34)
}

// MARK: - Widget view

struct BycreepWeekWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: BycreepWeekEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var todayWeekday: Int { WeekClock.weekdayIndex(for: entry.date) }
    private var todayKey: String { WeekClock.dateKey(entry.date) }
    private var weekDateKeys: [String] {
        WeekClock.weekDates(containing: entry.date).map(WeekClock.dateKey)
    }
    private var isTodayTraining: Bool { snapshot.trainingWeekdays.contains(todayWeekday) }
    private var isTodayCompleted: Bool { snapshot.completedDateKeys.contains(todayKey) }

    var body: some View {
        Group {
            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .widgetURL(BycreepShared.deepLinkURL)
    }

    private var widgetBackground: some View {
        ZStack {
            Color.black
            if isTodayTraining {
                RadialGradient(
                    colors: [WidgetTheme.red.opacity(0.16), .clear],
                    center: .top,
                    startRadius: 4,
                    endRadius: 190
                )
            }
        }
    }

    // MARK: Medium

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                wordmark(size: 21)

                Spacer(minLength: 8)

                Text((snapshot.programName ?? "НЕТ ПРОГРАММЫ").uppercased())
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(WidgetTheme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 7)

            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { weekday in
                    WidgetDayDot(
                        weekday: weekday,
                        isTraining: snapshot.trainingWeekdays.contains(weekday),
                        isCompleted: isCompleted(weekday),
                        isToday: weekday == todayWeekday,
                        compact: false
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer(minLength: 6)

            statusLine(compact: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: Small

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                wordmark(size: 17)
                Spacer(minLength: 4)
                if isTodayTraining {
                    Circle()
                        .fill(WidgetTheme.red)
                        .frame(width: 5, height: 5)
                }
            }

            Spacer(minLength: 5)

            HStack(spacing: 2) {
                ForEach(1...4, id: \.self) { weekday in
                    smallDot(weekday)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                ForEach(5...7, id: \.self) { weekday in
                    smallDot(weekday)
                }
            }

            Spacer(minLength: 4)

            statusLine(compact: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func smallDot(_ weekday: Int) -> some View {
        WidgetDayDot(
            weekday: weekday,
            isTraining: snapshot.trainingWeekdays.contains(weekday),
            isCompleted: isCompleted(weekday),
            isToday: weekday == todayWeekday,
            compact: true
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: Pieces

    private func wordmark(size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("bycreep")
                .font(.system(size: size, weight: .black))
                .tracking(-0.8)
                .foregroundStyle(WidgetTheme.text)
            Circle()
                .fill(WidgetTheme.red)
                .frame(width: max(4, size * 0.18), height: max(4, size * 0.18))
                .offset(y: -size * 0.38)
        }
        .accessibilityLabel("bycreep")
    }

    private func statusLine(compact: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 4, height: 4)

            Text(statusText)
                .font(.system(size: compact ? 7.5 : 8.5, weight: .bold))
                .tracking(compact ? 0.3 : 0.7)
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            if !compact && !snapshot.trainingWeekdays.isEmpty {
                Text("\(snapshot.trainingWeekdays.count) ДН.")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(WidgetTheme.tertiary)
            }
        }
    }

    private var statusText: String {
        if snapshot.trainingWeekdays.isEmpty {
            return "ДОБАВЬ ПРОГРАММУ"
        }
        if isTodayTraining {
            return isTodayCompleted ? "СЕГОДНЯ ЗАКРЫТО" : "СЕГОДНЯ ТРЕНИРОВКА"
        }
        return "СЕГОДНЯ ОТДЫХ"
    }

    private var statusColor: Color {
        if snapshot.trainingWeekdays.isEmpty {
            return WidgetTheme.tertiary
        }
        if isTodayTraining {
            return isTodayCompleted ? WidgetTheme.text : WidgetTheme.red
        }
        return WidgetTheme.secondary
    }

    private func isCompleted(_ weekday: Int) -> Bool {
        guard weekDateKeys.indices.contains(weekday - 1) else { return false }
        return snapshot.completedDateKeys.contains(weekDateKeys[weekday - 1])
    }
}

// MARK: - Day circle

private struct WidgetDayDot: View {
    let weekday: Int
    let isTraining: Bool
    let isCompleted: Bool
    let isToday: Bool
    let compact: Bool

    private var isGlowing: Bool { isToday && isTraining }
    private var size: CGFloat { compact ? 21 : 34 }

    private var fillStyle: AnyShapeStyle {
        if isGlowing {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [WidgetTheme.red, WidgetTheme.deepRed],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        if isTraining {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(Color.white.opacity(isToday ? 0.08 : 0.035))
    }

    private var strokeColor: Color {
        if isGlowing { return Color.white.opacity(0.28) }
        if isTraining { return .clear }
        return Color.white.opacity(isToday ? 0.72 : 0.30)
    }

    private var iconColor: Color {
        isGlowing ? WidgetTheme.text : Color.black
    }

    private var labelColor: Color {
        if isGlowing { return WidgetTheme.red }
        if isTraining { return WidgetTheme.text }
        if isToday { return WidgetTheme.secondary }
        return WidgetTheme.tertiary
    }

    var body: some View {
        VStack(spacing: compact ? 3.5 : 6) {
            ZStack {
                Circle()
                    .fill(fillStyle)

                Circle()
                    .strokeBorder(strokeColor, lineWidth: 1.1)

                if isTraining {
                    Image(systemName: isCompleted ? "checkmark" : "dumbbell.fill")
                        .font(.system(size: size * 0.32, weight: .black))
                        .foregroundStyle(iconColor)
                } else if isToday {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                }
            }
            .frame(width: size, height: size)
            .shadow(
                color: isGlowing ? WidgetTheme.red.opacity(0.95) : .clear,
                radius: isGlowing ? 10 : 0
            )

            Text(WeekClock.shortLabels[weekday - 1])
                .font(.system(size: compact ? 7.5 : 9.5, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [WeekClock.fullLabels[weekday - 1]]
        parts.append(isTraining ? "тренировка" : "отдых")
        if isCompleted { parts.append("выполнено") }
        if isToday { parts.append("сегодня") }
        return parts.joined(separator: ", ")
    }
}
