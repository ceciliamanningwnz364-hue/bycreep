import Foundation
import SwiftData

@MainActor
enum ProgramStore {
    /// Creates and activates a generated program. Returns false when the
    /// context could not be persisted; callers should roll back and inform.
    @discardableResult
    static func saveGenerated(_ plan: TrainingPlan, context: ModelContext) -> Bool {
        deactivateAll(context: context)

        let program = Program(
            name: plan.name,
            source: "generated",
            isActive: true,
            notes: plan.notes
        )
        context.insert(program)

        for (dayIndex, planDay) in plan.days.enumerated() {
            let day = ProgramDay(
                weekday: planDay.weekday,
                title: planDay.title,
                order: dayIndex
            )
            context.insert(day)
            program.days.append(day)

            for (exerciseIndex, planExercise) in planDay.exercises.enumerated() {
                let exercise = ProgramExercise(
                    name: planExercise.name,
                    muscle: planExercise.muscle,
                    sets: planExercise.sets,
                    repsLow: planExercise.repsLow,
                    repsHigh: planExercise.repsHigh,
                    restSeconds: planExercise.restSeconds,
                    targetWeightKg: planExercise.targetWeightKg,
                    note: planExercise.note,
                    order: exerciseIndex
                )
                context.insert(exercise)
                day.exercises.append(exercise)
            }
        }

        guard save(context) else { return false }
        WidgetBridge.refresh(context: context)
        return true
    }

    static func activate(_ program: Program, context: ModelContext) {
        deactivateAll(context: context)
        program.isActive = true
        save(context)
        WidgetBridge.refresh(context: context)
    }

    static func deactivateAll(context: ModelContext) {
        let programs = (try? context.fetch(FetchDescriptor<Program>())) ?? []
        for item in programs {
            item.isActive = false
        }
    }

    static func delete(_ program: Program, context: ModelContext) {
        let wasActive = program.isActive
        context.delete(program)
        save(context)
        if wasActive {
            WidgetBridge.refresh(context: context)
        }
    }

    /// Persists pending changes. Returns false when SwiftData could not save,
    /// letting creation flows surface an error instead of silently losing data.
    @discardableResult
    static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            assertionFailure("SwiftData save failed: \(error)")
            return false
        }
    }
}
