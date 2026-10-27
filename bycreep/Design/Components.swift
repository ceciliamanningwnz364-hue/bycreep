import SwiftUI

// MARK: - Surfaces

private struct ByCardModifier: ViewModifier {
    let padding: CGFloat
    let radius: CGFloat
    let fill: Color

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            }
    }
}

extension View {
    func byCard(
        padding: CGFloat = Theme.cardPadding,
        radius: CGFloat = Theme.radius,
        fill: Color = Theme.surface
    ) -> some View {
        modifier(ByCardModifier(padding: padding, radius: radius, fill: fill))
    }

    func byField(minHeight: CGFloat = 50) -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: minHeight)
            .background(Theme.surfaceSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            }
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ByFont.heavy(14))
            .textCase(.uppercase)
            .tracking(0.9)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 18)
            .background(
                Theme.redGradient,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(
                color: Theme.red.opacity(configuration.isPressed ? 0.12 : 0.24),
                radius: 14,
                y: 8
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct LightButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ByFont.heavy(14))
            .textCase(.uppercase)
            .tracking(0.9)
            .foregroundStyle(Theme.bg)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ByFont.heavy(14))
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(configuration.isPressed ? 0.09 : 0.035))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Theme.strokeStrong, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

// MARK: - Headers

struct ScreenTitle: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(ByFont.label)
                .tracking(1.8)
                .foregroundStyle(Theme.red)
            Text(title)
                .font(ByFont.display(34))
                .tracking(-1)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(ByFont.label)
                    .tracking(1.3)
                    .foregroundStyle(Theme.secondary)
                if let subtitle {
                    Text(subtitle)
                        .font(ByFont.regular(12))
                        .foregroundStyle(Theme.tertiary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(ByFont.semibold(12))
                    .foregroundStyle(Theme.red)
            }
        }
    }
}

// MARK: - Week strip

struct WeekStripView: View {
    let trainingWeekdays: Set<Int>
    let completedDateKeys: Set<String>
    var today: Date = .now
    var circleSize: CGFloat = 34
    var spacing: CGFloat = 5

    var body: some View {
        let dates = WeekClock.weekDates(containing: today)
        HStack(spacing: spacing) {
            ForEach(dates.indices, id: \.self) { index in
                let date = dates[index]
                let weekday = index + 1
                WeekDayDot(
                    weekday: weekday,
                    isTraining: trainingWeekdays.contains(weekday),
                    isCompleted: completedDateKeys.contains(WeekClock.dateKey(date)),
                    isToday: WeekClock.isSameDay(date, today),
                    circleSize: circleSize
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct WeekDayDot: View {
    let weekday: Int
    let isTraining: Bool
    let isCompleted: Bool
    let isToday: Bool
    let circleSize: CGFloat

    private var isTodayTraining: Bool { isToday && isTraining }

    private var circleStyle: AnyShapeStyle {
        if isTodayTraining {
            return AnyShapeStyle(Theme.redGradient)
        }
        if isTraining {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(Color.white.opacity(0.035))
    }

    private var strokeColor: Color {
        if isTodayTraining { return Color.white.opacity(0.28) }
        if isTraining { return Color.clear }
        return isToday ? Color.white.opacity(0.65) : Theme.strokeStrong
    }

    private var iconColor: Color {
        isTodayTraining ? Theme.text : Theme.bg
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(circleStyle)
                    .frame(width: circleSize, height: circleSize)
                    .overlay {
                        Circle()
                            .strokeBorder(strokeColor, lineWidth: 1.3)
                            .frame(width: circleSize, height: circleSize)
                    }
                    .shadow(
                        color: isTodayTraining ? Theme.red.opacity(0.85) : .clear,
                        radius: 11
                    )

                if isTraining {
                    Image(systemName: isCompleted ? "checkmark" : "dumbbell.fill")
                        .font(.system(size: circleSize * 0.34, weight: .black))
                        .foregroundStyle(iconColor)
                } else if isToday {
                    Circle()
                        .fill(Theme.text)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: circleSize, height: circleSize)

            Text(WeekClock.shortLabels[weekday - 1])
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(
                    isTodayTraining ? Theme.red : isTraining ? Theme.text : Theme.tertiary
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(WeekClock.fullLabels[weekday - 1]), \(isTraining ? "тренировка" : "отдых")\(isCompleted ? ", выполнено" : "")"
        )
    }
}

// MARK: - Rings & metrics

struct ActivityRing: View {
    let progress: Double
    let value: String
    let caption: String
    var size: CGFloat = 144
    var lineWidth: CGFloat = 12
    var tint: Color = Theme.red

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.055), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: progress)

            VStack(spacing: 2) {
                Text(value)
                    .font(ByFont.display(size * 0.20))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(caption.uppercased())
                    .font(ByFont.micro)
                    .tracking(0.9)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, lineWidth + 8)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption): \(value)")
    }
}

struct MacroBarView: View {
    let title: String
    let current: Double
    let goal: Double
    var tint: Color = Theme.text

    private var progress: Double {
        goal > 0 ? min(max(current / goal, 0), 1) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Text(title)
                    .font(ByFont.semibold(11))
                    .foregroundStyle(Theme.secondary)
                Spacer(minLength: 2)
                Text("\(Formatters.integer(current)) / \(Formatters.integer(goal)) г")
                    .font(ByFont.mono(10, weight: .medium))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(proxy.size.width * progress, progress > 0 ? 4 : 0))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var detail: String? = nil
    var symbol: String? = nil
    var accent: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent)
                }
                Text(title.uppercased())
                    .font(ByFont.micro)
                    .tracking(0.8)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(value)
                .font(ByFont.heavy(24))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let detail {
                Text(detail)
                    .font(ByFont.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .byCard(padding: 14, radius: 18)
    }
}

// MARK: - Navigation / controls

struct SegmentBar: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(titles.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        selection = index
                    }
                    Haptics.tap()
                } label: {
                    Text(titles[index])
                        .font(ByFont.semibold(12))
                        .foregroundStyle(selection == index ? Theme.text : Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selection == index {
                                Capsule()
                                    .fill(Theme.red)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.surface, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }
}

struct TagPill: View {
    let text: String
    var color: Color = Theme.text
    var fill: Color = Color.white.opacity(0.07)

    var body: some View {
        Text(text.uppercased())
            .font(ByFont.micro)
            .tracking(0.7)
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(fill, in: Capsule())
    }
}

struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ByFont.semibold(13))
                .foregroundStyle(isSelected ? Theme.bg : Theme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ? Color.white : Color.white.opacity(0.04),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.clear : Theme.stroke,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Theme.red)
                .frame(width: 64, height: 64)
                .background(Theme.redSoft, in: Circle())

            Text(title)
                .font(ByFont.heavy(18))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)

            Text(message)
                .font(ByFont.regular(13))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(GhostButtonStyle())
                    .frame(maxWidth: 240)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 20)
            }
            Text(title)
                .font(ByFont.regular(14))
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(ByFont.semibold(14))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ByDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 1)
    }
}
