import Foundation

enum Formatters {
    static let ru = Locale(identifier: "ru_RU")

    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter
    }()

    private static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    private static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let weekdayShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = ru
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter
    }()

    static func shortDate(_ date: Date) -> String {
        shortDate.string(from: date)
    }

    static func dayMonthUppercased(_ date: Date) -> String {
        dayMonth.string(from: date).uppercased(with: ru)
    }

    static func monthYearTitle(_ date: Date) -> String {
        monthYear.string(from: date).capitalized(with: ru)
    }

    static func time(_ date: Date) -> String {
        time.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        weekdayShort.string(from: date).uppercased(with: ru)
    }

    static func fullDate(_ date: Date) -> String {
        fullDate.string(from: date)
    }

    static func weekdayFull(_ weekday: Int) -> String {
        let index = min(max(weekday, 1), 7) - 1
        return WeekClock.fullLabels[index]
    }

    static func weekdayShort(_ weekday: Int) -> String {
        let index = min(max(weekday, 1), 7) - 1
        return WeekClock.shortLabels[index]
    }

    static func number(_ value: Double, maxFraction: Int = 1) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0...maxFraction))
                .locale(ru)
        )
    }

    static func integer(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(0))
                .locale(ru)
        )
    }

    static func kg(_ value: Double, maxFraction: Int = 1) -> String {
        "\(number(value, maxFraction: maxFraction)) кг"
    }

    static func kcal(_ value: Double) -> String {
        "\(integer(value)) ккал"
    }

    static func grams(_ value: Double) -> String {
        "\(integer(value)) г"
    }

    static func volume(_ value: Double) -> String {
        if value <= 0 { return "—" }
        return "\(integer(value)) кг"
    }

    static func timer(_ seconds: Int) -> String {
        let clamped = max(seconds, 0)
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    static func duration(minutes: Int) -> String {
        "\(minutes) мин"
    }

    static func relativeTrainingDate(_ date: Date) -> String {
        let cal = WeekClock.calendar
        if cal.isDateInToday(date) { return "Сегодня" }
        if cal.isDateInTomorrow(date) { return "Завтра" }
        let label = weekdayFull(WeekClock.weekdayIndex(for: date)).lowercased(with: ru)
        return "В \(label)"
    }

    /// Russian plural form: 1 тренировка, 2 тренировки, 5 тренировок.
    static func plural(_ count: Int, one: String, few: String, many: String) -> String {
        let mod100 = abs(count) % 100
        let mod10 = abs(count) % 10
        if mod100 >= 11 && mod100 <= 14 { return many }
        if mod10 == 1 { return one }
        if mod10 >= 2 && mod10 <= 4 { return few }
        return many
    }

    static func workouts(_ count: Int) -> String {
        "\(count) \(plural(count, one: "тренировка", few: "тренировки", many: "тренировок"))"
    }

    static func sets(_ count: Int) -> String {
        "\(count) \(plural(count, one: "подход", few: "подхода", many: "подходов"))"
    }

    static func exercises(_ count: Int) -> String {
        "\(count) \(plural(count, one: "упражнение", few: "упражнения", many: "упражнений"))"
    }

    static func days(_ count: Int) -> String {
        "\(count) \(plural(count, one: "день", few: "дня", many: "дней"))"
    }
}
