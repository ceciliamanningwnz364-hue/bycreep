import Foundation

// MARK: - Generated plan (plain values, no SwiftData)

struct TrainingPlanExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscle: String
    let sets: Int
    let repsLow: Int
    let repsHigh: Int
    let restSeconds: Int
    let targetWeightKg: Double?
    let note: String

    var repsLabel: String {
        repsLow == repsHigh ? "\(repsLow)" : "\(repsLow)–\(repsHigh)"
    }
}

struct TrainingPlanDay: Identifiable {
    let id = UUID()
    let weekday: Int
    let title: String
    let focus: String
    let exercises: [TrainingPlanExercise]

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets } }
    var estimatedMinutes: Int {
        max(25, totalSets * 3 + exercises.count * 2 + 8)
    }
}

struct TrainingPlan: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let notes: String
    let days: [TrainingPlanDay]

    var trainingWeekdays: [Int] { days.map(\.weekday) }
}

// MARK: - Generator

enum WorkoutGenerator {
    static func generate(for profile: UserProfile, trainingDays: Int? = nil) -> TrainingPlan {
        let requestedDays = trainingDays ?? profile.trainingDaysPerWeek
        let dayCount = min(max(requestedDays, 2), 6)
        let specs = daySpecs(for: dayCount)
        let weekdays = weekdays(for: dayCount)

        let days: [TrainingPlanDay] = specs.enumerated().map { index, spec in
            let exercises = spec.exercises.map { exerciseSpec -> TrainingPlanExercise in
                makeExercise(from: exerciseSpec, profile: profile)
            }
            return TrainingPlanDay(
                weekday: weekdays[index],
                title: spec.title,
                focus: spec.focus,
                exercises: exercises
            )
        }

        return TrainingPlan(
            name: "BYCREEP HEAVY · \(dayCount) \(Formatters.plural(dayCount, one: "день", few: "дня", many: "дней"))",
            subtitle: "\(splitName(dayCount)) · \(profile.goal.title.lowercased()) · \(profile.experience.title.lowercased())",
            notes: trainingNotes(dayCount: dayCount),
            days: days
        )
    }

    // MARK: Exercise generation

    private static func makeExercise(
        from spec: ExerciseSpec,
        profile: UserProfile
    ) -> TrainingPlanExercise {
        let meta = library[spec.name] ?? ExerciseMeta(muscle: "Разное", loadFactor: 0.15)
        let isBeginner = profile.experience == .beginner
        let isAdvanced = profile.experience == .advanced

        let sets = min(max(spec.sets + (isAdvanced ? 1 : isBeginner ? -1 : 0), 2), 6)
        let repBoost = isBeginner ? 2 : 0
        let repsLow = max(spec.repsLow + repBoost, 3)
        let repsHigh = max(spec.repsHigh + repBoost, repsLow)

        var rest = spec.rest
        if isAdvanced { rest += 15 }
        if profile.goal == .cut { rest -= 15 }
        rest = max(rest, 45)

        var weight: Double?
        var note = meta.note
        if meta.loadFactor > 0 {
            let raw = profile.weightKg * meta.loadFactor * profile.experience.startWeightMultiplier
            let step = meta.perHand || raw < 25 ? 1.0 : 2.5
            weight = max(step, (raw / step).rounded() * step)
        }
        if meta.perHand {
            note = note.isEmpty ? "вес на одну гантель" : note + " · на одну гантель"
        }
        if weight == nil && meta.loadFactor == 0 {
            note = note.isEmpty ? "свой вес" : note
        }

        return TrainingPlanExercise(
            name: spec.name,
            muscle: meta.muscle,
            sets: sets,
            repsLow: repsLow,
            repsHigh: repsHigh,
            restSeconds: rest,
            targetWeightKg: weight,
            note: note
        )
    }

    // MARK: Weekly scaffold

    private static func weekdays(for dayCount: Int) -> [Int] {
        switch dayCount {
        case 2: return [1, 4]
        case 3: return [1, 3, 5]
        case 4: return [1, 2, 4, 5]
        case 5: return [1, 2, 3, 5, 6]
        case 6: return [1, 2, 3, 4, 5, 6]
        default: return [1, 3, 5]
        }
    }

    private static func splitName(_ dayCount: Int) -> String {
        switch dayCount {
        case 2: return "Full Body"
        case 3: return "Full Body ×3"
        case 4: return "Upper / Lower"
        case 5: return "PPL + Upper / Lower"
        case 6: return "Push / Pull / Legs ×2"
        default: return "Full Body"
        }
    }

    private static func trainingNotes(dayCount: Int) -> String {
        """
        Тяжёлый силовой блок на \(dayCount) \(Formatters.plural(dayCount, one: "день", few: "дня", many: "дней")) в неделю.

        • В рабочих подходах оставляй 1–2 повторения в запасе.
        • База: отдых 2–3 минуты, изоляция — 60–90 секунд.
        • Прогрессия: сделал верх диапазона во всех подходах — добавь минимальный шаг веса.
        • Веса в карточках — ориентировочный старт. Подбирай по технике, а не по эго.
        • Разминка: 5–10 минут + 2 лёгких подхода в первом упражнении.
        • Боль в суставе — стоп. Тренировка не должна травмировать.
        """
    }

    // MARK: Split recipes

    private static func daySpecs(for dayCount: Int) -> [DaySpec] {
        switch dayCount {
        case 2:
            return [
                DaySpec(title: "FULL A", focus: "Всё тело · тяжёлый низ", exercises: [
                    ex("Приседания со штангой", 4, 5, 5, 180),
                    ex("Жим штанги лёжа", 4, 5, 5, 180),
                    ex("Тяга штанги в наклоне", 4, 6, 6, 150),
                    ex("Жим гантелей стоя", 3, 8, 8, 120),
                    ex("Подтягивания", 3, 6, 8, 120),
                    ex("Планка", 3, 45, 45, 60)
                ]),
                DaySpec(title: "FULL B", focus: "Всё тело · тяжёлый верх", exercises: [
                    ex("Румынская тяга", 4, 6, 6, 150),
                    ex("Жим гантелей на наклонной", 4, 8, 8, 120),
                    ex("Тяга верхнего блока", 4, 8, 8, 120),
                    ex("Жим ногами", 3, 10, 10, 120),
                    ex("Махи гантелями в стороны", 3, 12, 12, 60),
                    ex("Сгибания на бицепс", 3, 10, 10, 60),
                    ex("Подъёмы на икры стоя", 3, 12, 12, 60)
                ])
            ]
        case 3:
            return [
                DaySpec(title: "FULL A", focus: "Всё тело · сила", exercises: [
                    ex("Приседания со штангой", 4, 5, 5, 180),
                    ex("Жим штанги лёжа", 4, 5, 5, 180),
                    ex("Тяга штанги в наклоне", 4, 6, 6, 150),
                    ex("Махи гантелями в стороны", 3, 12, 12, 60),
                    ex("Сгибания на бицепс", 3, 10, 10, 60),
                    ex("Планка", 3, 45, 45, 60)
                ]),
                DaySpec(title: "FULL B", focus: "Задняя цепь · жим", exercises: [
                    ex("Становая тяга", 3, 5, 5, 180),
                    ex("Жим штанги стоя", 4, 6, 6, 150),
                    ex("Подтягивания", 4, 6, 8, 120),
                    ex("Выпады с гантелями", 3, 10, 10, 90),
                    ex("Отжимания на брусьях", 3, 8, 8, 90),
                    ex("Face pull", 3, 12, 12, 60)
                ]),
                DaySpec(title: "FULL C", focus: "Объём · ноги", exercises: [
                    ex("Приседания со штангой", 4, 6, 6, 180),
                    ex("Жим штанги на наклонной", 4, 8, 8, 120),
                    ex("Тяга гантели одной рукой", 3, 10, 10, 90),
                    ex("Жим ногами", 3, 10, 10, 120),
                    ex("Французский жим", 3, 10, 10, 60),
                    ex("Подъёмы на икры стоя", 4, 12, 12, 60)
                ])
            ]
        case 4:
            return [
                DaySpec(title: "UPPER A", focus: "Верх тела · тяжёлый жим", exercises: [
                    ex("Жим штанги лёжа", 4, 5, 5, 180),
                    ex("Тяга штанги в наклоне", 4, 6, 6, 150),
                    ex("Жим гантелей стоя", 3, 8, 8, 120),
                    ex("Подтягивания", 3, 8, 8, 120),
                    ex("Французский жим", 3, 10, 10, 60),
                    ex("Сгибания на бицепс", 3, 10, 10, 60)
                ]),
                DaySpec(title: "LOWER A", focus: "Ноги · приседание", exercises: [
                    ex("Приседания со штангой", 4, 5, 5, 180),
                    ex("Румынская тяга", 3, 8, 8, 150),
                    ex("Жим ногами", 3, 10, 10, 120),
                    ex("Сгибания ног лёжа", 3, 12, 12, 80),
                    ex("Подъёмы на икры стоя", 4, 12, 12, 60),
                    ex("Планка", 3, 45, 45, 60)
                ]),
                DaySpec(title: "UPPER B", focus: "Верх тела · объём", exercises: [
                    ex("Жим штанги на наклонной", 4, 8, 8, 120),
                    ex("Тяга верхнего блока", 4, 10, 10, 120),
                    ex("Жим Арнольда", 3, 10, 10, 90),
                    ex("Тяга гантели одной рукой", 3, 10, 10, 90),
                    ex("Махи гантелями в стороны", 3, 12, 12, 60),
                    ex("Молотковые сгибания", 3, 12, 12, 60)
                ]),
                DaySpec(title: "LOWER B", focus: "Ноги · тяга", exercises: [
                    ex("Становая тяга", 3, 5, 5, 180),
                    ex("Выпады с гантелями", 3, 10, 10, 90),
                    ex("Разгибания ног", 3, 12, 12, 80),
                    ex("Сгибания ног лёжа", 3, 12, 12, 80),
                    ex("Подъёмы на икры стоя", 3, 15, 15, 60),
                    ex("Скручивания на пресс", 3, 20, 20, 60)
                ])
            ]
        case 5:
            return [
                DaySpec(title: "PUSH", focus: "Грудь · плечи · трицепс", exercises: [
                    ex("Жим штанги лёжа", 4, 5, 5, 180),
                    ex("Жим штанги на наклонной", 3, 8, 8, 120),
                    ex("Жим штанги стоя", 3, 6, 6, 150),
                    ex("Махи гантелями в стороны", 3, 12, 12, 60),
                    ex("Французский жим", 3, 10, 10, 60)
                ]),
                DaySpec(title: "PULL", focus: "Спина · бицепс", exercises: [
                    ex("Становая тяга", 4, 5, 5, 180),
                    ex("Тяга штанги в наклоне", 4, 6, 6, 150),
                    ex("Подтягивания", 3, 8, 8, 120),
                    ex("Face pull", 3, 12, 12, 60),
                    ex("Сгибания на бицепс", 3, 10, 10, 60)
                ]),
                DaySpec(title: "LEGS", focus: "Ноги · ягодицы · икры", exercises: [
                    ex("Приседания со штангой", 4, 5, 5, 180),
                    ex("Румынская тяга", 3, 8, 8, 150),
                    ex("Жим ногами", 3, 10, 10, 120),
                    ex("Сгибания ног лёжа", 3, 12, 12, 80),
                    ex("Подъёмы на икры стоя", 4, 12, 12, 60)
                ]),
                DaySpec(title: "UPPER", focus: "Верх тела · объём", exercises: [
                    ex("Жим штанги на наклонной", 4, 6, 6, 150),
                    ex("Тяга верхнего блока", 4, 10, 10, 120),
                    ex("Жим Арнольда", 3, 8, 8, 90),
                    ex("Тяга гантели одной рукой", 3, 10, 10, 90),
                    ex("Махи гантелями в стороны", 3, 15, 15, 60),
                    ex("Молотковые сгибания", 3, 12, 12, 60)
                ]),
                DaySpec(title: "LOWER", focus: "Ноги · объём", exercises: [
                    ex("Жим ногами", 4, 8, 8, 120),
                    ex("Ягодичный мост", 3, 10, 10, 120),
                    ex("Выпады с гантелями", 3, 10, 10, 90),
                    ex("Разгибания ног", 3, 12, 12, 80),
                    ex("Сгибания ног лёжа", 3, 12, 12, 80),
                    ex("Подъёмы на икры стоя", 3, 15, 15, 60)
                ])
            ]
        default:
            return [
                DaySpec(title: "PUSH A", focus: "Грудь · плечи · трицепс", exercises: [
                    ex("Жим штанги лёжа", 5, 5, 5, 180),
                    ex("Жим штанги стоя", 4, 6, 6, 150),
                    ex("Жим штанги на наклонной", 3, 8, 8, 120),
                    ex("Махи гантелями в стороны", 3, 12, 12, 60),
                    ex("Французский жим", 3, 10, 10, 60)
                ]),
                DaySpec(title: "PULL A", focus: "Спина · бицепс", exercises: [
                    ex("Становая тяга", 4, 5, 5, 210),
                    ex("Тяга штанги в наклоне", 4, 6, 6, 150),
                    ex("Подтягивания", 4, 6, 8, 120),
                    ex("Face pull", 3, 12, 12, 60),
                    ex("Сгибания на бицепс", 3, 10, 10, 60)
                ]),
                DaySpec(title: "LEGS A", focus: "Ноги · тяжёлый низ", exercises: [
                    ex("Приседания со штангой", 4, 5, 5, 180),
                    ex("Румынская тяга", 3, 8, 8, 150),
                    ex("Жим ногами", 3, 10, 10, 120),
                    ex("Сгибания ног лёжа", 3, 12, 12, 80),
                    ex("Подъёмы на икры стоя", 4, 10, 10, 60)
                ]),
                DaySpec(title: "PUSH B", focus: "Грудь · плечи · трицепс", exercises: [
                    ex("Жим в тренажёре «Хаммер»", 4, 10, 10, 120),
                    ex("Жим Арнольда", 3, 10, 10, 90),
                    ex("Разведения гантелей", 3, 12, 12, 60),
                    ex("Махи гантелями в стороны", 3, 15, 15, 60),
                    ex("Разгибания на трицепс", 3, 12, 12, 60)
                ]),
                DaySpec(title: "PULL B", focus: "Спина · бицепс", exercises: [
                    ex("Тяга Т-грифа", 4, 8, 8, 150),
                    ex("Тяга верхнего блока узким хватом", 4, 10, 10, 120),
                    ex("Тяга гантели одной рукой", 3, 10, 10, 90),
                    ex("Обратные разведения", 3, 15, 15, 60),
                    ex("Молотковые сгибания", 3, 12, 12, 60)
                ]),
                DaySpec(title: "LEGS B", focus: "Ноги · объём", exercises: [
                    ex("Гакк-приседания", 4, 8, 8, 150),
                    ex("Ягодичный мост", 3, 10, 10, 120),
                    ex("Выпады с гантелями", 3, 12, 12, 90),
                    ex("Разгибания ног", 3, 12, 12, 80),
                    ex("Сгибания ног лёжа", 3, 15, 15, 80),
                    ex("Подъёмы на икры стоя", 3, 15, 15, 60)
                ])
            ]
        }
    }

    // MARK: Small value types

    private struct ExerciseSpec {
        let name: String
        let sets: Int
        let repsLow: Int
        let repsHigh: Int
        let rest: Int
    }

    private struct DaySpec {
        let title: String
        let focus: String
        let exercises: [ExerciseSpec]
    }

    private struct ExerciseMeta {
        let muscle: String
        let loadFactor: Double
        var perHand: Bool = false
        var note: String = ""
    }

    private static func ex(_ name: String, _ sets: Int, _ low: Int, _ high: Int, _ rest: Int) -> ExerciseSpec {
        ExerciseSpec(name: name, sets: sets, repsLow: low, repsHigh: high, rest: rest)
    }

    // MARK: Exercise library

    private static let library: [String: ExerciseMeta] = [
        "Приседания со штангой": ExerciseMeta(muscle: "Ноги", loadFactor: 0.50),
        "Жим штанги лёжа": ExerciseMeta(muscle: "Грудь", loadFactor: 0.35),
        "Тяга штанги в наклоне": ExerciseMeta(muscle: "Спина", loadFactor: 0.35),
        "Жим гантелей стоя": ExerciseMeta(muscle: "Плечи", loadFactor: 0.18, perHand: true),
        "Подтягивания": ExerciseMeta(muscle: "Спина", loadFactor: 0, note: "свой вес · при необходимости резинка"),
        "Планка": ExerciseMeta(muscle: "Кор", loadFactor: 0, note: "секунды, а не повторения"),
        "Румынская тяга": ExerciseMeta(muscle: "Ноги", loadFactor: 0.40),
        "Жим гантелей на наклонной": ExerciseMeta(muscle: "Грудь", loadFactor: 0.20, perHand: true),
        "Тяга верхнего блока": ExerciseMeta(muscle: "Спина", loadFactor: 0.40),
        "Жим ногами": ExerciseMeta(muscle: "Ноги", loadFactor: 0.80),
        "Махи гантелями в стороны": ExerciseMeta(muscle: "Плечи", loadFactor: 0.05, perHand: true),
        "Сгибания на бицепс": ExerciseMeta(muscle: "Бицепс", loadFactor: 0.15),
        "Подъёмы на икры стоя": ExerciseMeta(muscle: "Икры", loadFactor: 0.50),
        "Становая тяга": ExerciseMeta(muscle: "Спина", loadFactor: 0.60),
        "Жим штанги стоя": ExerciseMeta(muscle: "Плечи", loadFactor: 0.25),
        "Выпады с гантелями": ExerciseMeta(muscle: "Ноги", loadFactor: 0.10, perHand: true),
        "Отжимания на брусьях": ExerciseMeta(muscle: "Грудь", loadFactor: 0, note: "свой вес"),
        "Face pull": ExerciseMeta(muscle: "Плечи", loadFactor: 0.15),
        "Тяга гантели одной рукой": ExerciseMeta(muscle: "Спина", loadFactor: 0.20, perHand: true),
        "Французский жим": ExerciseMeta(muscle: "Трицепс", loadFactor: 0.10),
        "Скручивания на пресс": ExerciseMeta(muscle: "Кор", loadFactor: 0, note: "свой вес"),
        "Жим штанги на наклонной": ExerciseMeta(muscle: "Грудь", loadFactor: 0.30),
        "Молотковые сгибания": ExerciseMeta(muscle: "Бицепс", loadFactor: 0.10, perHand: true),
        "Разгибания ног": ExerciseMeta(muscle: "Ноги", loadFactor: 0.35),
        "Сгибания ног лёжа": ExerciseMeta(muscle: "Ноги", loadFactor: 0.25),
        "Жим в тренажёре «Хаммер»": ExerciseMeta(muscle: "Грудь", loadFactor: 0.35),
        "Разведения гантелей": ExerciseMeta(muscle: "Грудь", loadFactor: 0.05, perHand: true),
        "Жим Арнольда": ExerciseMeta(muscle: "Плечи", loadFactor: 0.12, perHand: true),
        "Разгибания на трицепс": ExerciseMeta(muscle: "Трицепс", loadFactor: 0.10),
        "Тяга верхнего блока узким хватом": ExerciseMeta(muscle: "Спина", loadFactor: 0.35),
        "Обратные разведения": ExerciseMeta(muscle: "Плечи", loadFactor: 0.04, perHand: true),
        "Гакк-приседания": ExerciseMeta(muscle: "Ноги", loadFactor: 0.50),
        "Ягодичный мост": ExerciseMeta(muscle: "Ягодицы", loadFactor: 0.60),
        "Тяга Т-грифа": ExerciseMeta(muscle: "Спина", loadFactor: 0.30)
    ]
}
