import Foundation
import SwiftData

@MainActor
enum SessionFactory {
    static func makeSession(
        day: ProgramDay,
        program: Program?,
        context: ModelContext
    ) -> WorkoutSession {
        let programName = program?.name ?? day.program?.name ?? "bycreep"
        let session = WorkoutSession(
            date: Date(),
            title: day.title,
            programName: programName
        )
        context.insert(session)

        for (index, planExercise) in day.orderedExercises.enumerated() {
            let exercise = SessionExercise(
                name: planExercise.name,
                muscle: planExercise.muscle,
                order: index,
                restSeconds: planExercise.restSeconds,
                note: planExercise.note
            )
            context.insert(exercise)
            session.exercises.append(exercise)

            for setIndex in 0..<max(planExercise.sets, 1) {
                let set = SetEntry(
                    order: setIndex,
                    reps: planExercise.repsLow,
                    weightKg: planExercise.targetWeightKg ?? 0
                )
                context.insert(set)
                exercise.sets.append(set)
            }
        }

        ProgramStore.save(context)
        return session
    }

    /// An unfinished workout can be resumed for a week, so closing the app
    /// overnight (or over a rest day) never loses logged sets.
    static let resumeWindowDays = 7

    static func resumeCutoffDate(now: Date = Date()) -> Date {
        let today = WeekClock.startOfDay(now)
        return WeekClock.calendar.date(
            byAdding: .day,
            value: -resumeWindowDays,
            to: today
        ) ?? today
    }

    static func resumableSession(context: ModelContext) -> WorkoutSession? {
        let cutoff = resumeCutoffDate()
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.isCompleted == false && session.date >= cutoff
            },
            sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    static func finish(_ session: WorkoutSession, context: ModelContext) {
        let now = Date()
        if let activeStartedAt = session.activeStartedAt {
            session.durationSeconds += max(0, Int(now.timeIntervalSince(activeStartedAt)))
        }
        session.activeStartedAt = nil
        session.finishedAt = now
        session.durationSeconds = max(session.durationSeconds, 60)
        session.isCompleted = true
        ProgramStore.save(context)
        WidgetBridge.refresh(context: context)
    }

    static func pause(_ session: WorkoutSession, context: ModelContext) {
        guard !session.isCompleted else { return }
        if let activeStartedAt = session.activeStartedAt {
            session.durationSeconds += max(0, Int(Date().timeIntervalSince(activeStartedAt)))
        }
        session.activeStartedAt = nil
        ProgramStore.save(context)
    }

    static func resume(_ session: WorkoutSession, context: ModelContext) {
        guard !session.isCompleted else { return }
        let now = Date()
        if let activeStartedAt = session.activeStartedAt {
            session.durationSeconds += max(0, Int(now.timeIntervalSince(activeStartedAt)))
        }
        session.activeStartedAt = now
        ProgramStore.save(context)
    }

    static func discard(_ session: WorkoutSession, context: ModelContext) {
        context.delete(session)
        ProgramStore.save(context)
    }
}
