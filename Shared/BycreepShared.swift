import Foundation

// MARK: - Shared configuration

enum BycreepShared {
    /// Must match the App Group added to BOTH targets in Signing & Capabilities.
    static let appGroupID = "group.com.bycreep.app"
    static let widgetKind = "BycreepWeekWidget"
    static let widgetSnapshotKey = "bycreep.widget.snapshot.v1"
    static let deepLinkURL = URL(string: "bycreep://today")!
}

// MARK: - Widget snapshot

/// A deliberately small payload. The widget never opens the SwiftData store,
/// so the extension stays fast and memory-light.
struct WidgetSnapshot: Codable, Equatable {
    var trainingWeekdays: [Int]      // 1 = Monday ... 7 = Sunday
    var completedDateKeys: [String]  // yyyy-MM-dd, only recent days
    var programName: String?
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        trainingWeekdays: [],
        completedDateKeys: [],
        programName: nil,
        updatedAt: .distantPast
    )

    func hasSameContent(as other: WidgetSnapshot) -> Bool {
        trainingWeekdays == other.trainingWeekdays
            && completedDateKeys == other.completedDateKeys
            && programName == other.programName
    }
}

enum WidgetSnapshotStore {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: BycreepShared.appGroupID) ?? .standard
    }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: BycreepShared.widgetSnapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Returns true when the widget has new data and should be reloaded.
    @discardableResult
    static func saveIfChanged(_ snapshot: WidgetSnapshot) -> Bool {
        if let current = load(), current.hasSameContent(as: snapshot) {
            return false
        }
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return false
        }
        defaults.set(data, forKey: BycreepShared.widgetSnapshotKey)
        return true
    }
}

// MARK: - Week helpers (shared by app + widget)

enum WeekClock {
    static let shortLabels = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]
    static let fullLabels = [
        "Понедельник", "Вторник", "Среда", "Четверг",
        "Пятница", "Суббота", "Воскресенье"
    ]

    /// Gregorian calendar with Monday as the first day, independent of device locale.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = .autoupdatingCurrent
        return calendar
    }

    /// Monday = 1 ... Sunday = 7.
    static func weekdayIndex(for date: Date = .now) -> Int {
        let systemWeekday = calendar.component(.weekday, from: date) // Sunday = 1
        return (systemWeekday + 5) % 7 + 1
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func startOfWeek(_ date: Date = .now) -> Date {
        let cal = calendar
        let parts = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: parts) ?? cal.startOfDay(for: date)
    }

    static func weekDates(containing date: Date = .now) -> [Date] {
        let start = startOfWeek(date)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// Stable key without allocating a DateFormatter.
    static func dateKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )
    }

    static func monthKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func nextTrainingDate(after date: Date = .now, weekdays: [Int]) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        let cal = calendar
        let today = cal.startOfDay(for: date)
        for offset in 0...7 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            if weekdays.contains(weekdayIndex(for: candidate)) {
                return candidate
            }
        }
        return nil
    }
}
