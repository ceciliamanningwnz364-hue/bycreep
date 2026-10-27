import Foundation
import SwiftData
import WidgetKit

/// Pushes a tiny, stable snapshot into the shared App Group and reloads the widget
/// only when the content actually changed.
@MainActor
enum WidgetBridge {
    static func refresh(context: ModelContext) {
        var programDescriptor = FetchDescriptor<Program>(
            predicate: #Predicate<Program> { $0.isActive == true },
            sortBy: [SortDescriptor(\Program.createdAt, order: .reverse)]
        )
        programDescriptor.fetchLimit = 1
        let activeProgram = (try? context.fetch(programDescriptor))?.first

        var sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.isCompleted == true },
            sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
        )
        sessionDescriptor.fetchLimit = 40
        let recentSessions = (try? context.fetch(sessionDescriptor)) ?? []

        let weekdays = Array(Set(activeProgram?.days.map(\.weekday) ?? [])).sorted()
        // A session belongs to the day it started, so a late-night workout
        // keeps its mark on the scheduled training day, not on the next one.
        let completedKeys = Array(Set(recentSessions.map { WeekClock.dateKey($0.date) }))
            .sorted()
            .suffix(35)

        let snapshot = WidgetSnapshot(
            trainingWeekdays: weekdays,
            completedDateKeys: Array(completedKeys),
            programName: activeProgram?.name,
            updatedAt: Date()
        )

        if WidgetSnapshotStore.saveIfChanged(snapshot) {
            WidgetCenter.shared.reloadTimelines(ofKind: BycreepShared.widgetKind)
        }
    }
}
