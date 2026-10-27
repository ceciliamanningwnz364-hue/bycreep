import SwiftUI
import WidgetKit

// MARK: - Entry

struct BycreepWeekEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Provider

struct BycreepWeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> BycreepWeekEntry {
        BycreepWeekEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (BycreepWeekEntry) -> Void
    ) {
        let snapshot = context.isPreview
            ? WidgetSnapshot.sample
            : (WidgetSnapshotStore.load() ?? .empty)
        completion(BycreepWeekEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<BycreepWeekEntry>) -> Void
    ) {
        let now = Date()
        let snapshot = WidgetSnapshotStore.load() ?? .empty
        let entry = BycreepWeekEntry(date: now, snapshot: snapshot)

        // Re-render just after midnight so the "today" glow moves to the
        // correct circle even when the app has not been opened.
        let startOfTomorrow = WeekClock.calendar.date(
            byAdding: .day,
            value: 1,
            to: WeekClock.startOfDay(now)
        ) ?? now.addingTimeInterval(86_400)
        let refreshDate = startOfTomorrow.addingTimeInterval(120)

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Widget

struct BycreepWeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: BycreepShared.widgetKind,
            provider: BycreepWeekProvider()
        ) { entry in
            BycreepWeekWidgetView(entry: entry)
        }
        .configurationDisplayName("bycreep · неделя")
        .description("Чёрный виджет с тренировочными днями. Сегодняшняя тренировка светится красным.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct BycreepWidgetBundle: WidgetBundle {
    var body: some Widget {
        BycreepWeekWidget()
    }
}

// MARK: - Preview data

private extension WidgetSnapshot {
    static var sample: WidgetSnapshot {
        let today = Date()
        return WidgetSnapshot(
            trainingWeekdays: [1, 3, 5],
            completedDateKeys: [WeekClock.dateKey(today)],
            programName: "Upper / Lower",
            updatedAt: today
        )
    }
}
