import Foundation
import SwiftData

// MARK: - Value types

enum Sex: String, CaseIterable, Codable, Identifiable {
    case male, female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Мужчина"
        case .female: return "Женщина"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary, light, moderate, high, athlete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sedentary: return "Сидячий"
        case .light: return "Лёгкая активность"
        case .moderate: return "Средняя активность"
        case .high: return "Высокая активность"
        case .athlete: return "Очень высокая"
        }
    }

    var shortTitle: String {
        switch self {
        case .sedentary: return "Сидячий"
        case .light: return "Лёгкий"
        case .moderate: return "Средний"
        case .high: return "Высокий"
        case .athlete: return "Максимум"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .high: return 1.725
        case .athlete: return 1.9
        }
    }
}

enum Goal: String, CaseIterable, Codable, Identifiable {
    case cut, maintain, gain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cut: return "Похудение"
        case .maintain: return "Поддержание"
        case .gain: return "Набор массы"
        }
    }

    var subtitle: String {
        switch self {
        case .cut: return "дефицит калорий"
        case .maintain: return "рекомпозиция"
        case .gain: return "профицит калорий"
        }
    }

    var calorieAdjustment: Double {
        switch self {
        case .cut: return -0.18
        case .maintain: return 0
        case .gain: return 0.10
        }
    }

    var proteinPerKg: Double {
        switch self {
        case .cut: return 2.2
        case .maintain: return 2.0
        case .gain: return 1.8
        }
    }

    var symbol: String {
        switch self {
        case .cut: return "arrow.down.right"
        case .maintain: return "arrow.right"
        case .gain: return "arrow.up.right"
        }
    }
}

enum Experience: String, CaseIterable, Codable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "Новичок"
        case .intermediate: return "Средний"
        case .advanced: return "Продвинутый"
        }
    }

    var startWeightMultiplier: Double {
        switch self {
        case .beginner: return 0.78
        case .intermediate: return 1.0
        case .advanced: return 1.18
        }
    }
}

enum PhotoAngle: String, CaseIterable, Codable, Identifiable {
    case front, side, back, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .front: return "Спереди"
        case .side: return "Сбоку"
        case .back: return "Сзади"
        case .other: return "Другое"
        }
    }
}

enum MealType: String, CaseIterable, Codable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Завтрак"
        case .lunch: return "Обед"
        case .dinner: return "Ужин"
        case .snack: return "Перекус"
        }
    }

    var symbol: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "leaf"
        }
    }
}

// MARK: - Profile

@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = ""
    var sexRaw: String = Sex.male.rawValue
    var age: Int = 25
    var heightCm: Double = 178
    var weightKg: Double = 78
    var activityRaw: String = ActivityLevel.moderate.rawValue
    var goalRaw: String = Goal.gain.rawValue
    var experienceRaw: String = Experience.intermediate.rawValue
    var trainingDaysPerWeek: Int = 4
    var createdAt: Date = Date()

    init(
        name: String = "",
        sex: Sex = .male,
        age: Int = 25,
        heightCm: Double = 178,
        weightKg: Double = 78,
        activity: ActivityLevel = .moderate,
        goal: Goal = .gain,
        experience: Experience = .intermediate,
        trainingDaysPerWeek: Int = 4
    ) {
        self.id = UUID()
        self.name = name
        self.sexRaw = sex.rawValue
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityRaw = activity.rawValue
        self.goalRaw = goal.rawValue
        self.experienceRaw = experience.rawValue
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.createdAt = Date()
    }

    var sex: Sex {
        get { Sex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    var activity: ActivityLevel {
        get { ActivityLevel(rawValue: activityRaw) ?? .moderate }
        set { activityRaw = newValue.rawValue }
    }

    var goal: Goal {
        get { Goal(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }

    var experience: Experience {
        get { Experience(rawValue: experienceRaw) ?? .intermediate }
        set { experienceRaw = newValue.rawValue }
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Атлет" : trimmed
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        return weightKg / pow(heightCm / 100, 2)
    }
}

// MARK: - Programs

@Model
final class Program {
    var id: UUID = UUID()
    var name: String = ""
    var source: String = "manual" // manual | generated
    var isActive: Bool = false
    var createdAt: Date = Date()
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \ProgramDay.program)
    var days: [ProgramDay] = []

    init(name: String, source: String = "manual", isActive: Bool = false, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.source = source
        self.isActive = isActive
        self.createdAt = Date()
        self.notes = notes
        self.days = []
    }

    var orderedDays: [ProgramDay] {
        days.sorted { lhs, rhs in
            if lhs.weekday == rhs.weekday { return lhs.order < rhs.order }
            return lhs.weekday < rhs.weekday
        }
    }

    var trainingWeekdays: [Int] {
        Array(Set(days.map(\.weekday))).sorted()
    }

    var totalExercises: Int {
        days.reduce(0) { $0 + $1.exercises.count }
    }

    var estimatedMinutes: Int {
        days.reduce(0) { partial, day in
            partial + day.exercises.reduce(0) { $0 + $1.sets * 3 + 5 }
        } / max(days.count, 1)
    }
}

@Model
final class ProgramDay {
    var id: UUID = UUID()
    var weekday: Int = 1 // Monday = 1
    var title: String = ""
    var order: Int = 0
    var program: Program?

    @Relationship(deleteRule: .cascade, inverse: \ProgramExercise.day)
    var exercises: [ProgramExercise] = []

    init(weekday: Int = 1, title: String = "Тренировка", order: Int = 0) {
        self.id = UUID()
        self.weekday = weekday
        self.title = title
        self.order = order
        self.exercises = []
    }

    var orderedExercises: [ProgramExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }

    var estimatedMinutes: Int {
        max(20, totalSets * 3 + exercises.count * 2 + 10)
    }
}

@Model
final class ProgramExercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscle: String = ""
    var sets: Int = 3
    var repsLow: Int = 8
    var repsHigh: Int = 12
    var restSeconds: Int = 90
    var targetWeightKg: Double? = nil
    var note: String = ""
    var order: Int = 0
    var day: ProgramDay?

    init(
        name: String,
        muscle: String = "",
        sets: Int = 3,
        repsLow: Int = 8,
        repsHigh: Int = 12,
        restSeconds: Int = 90,
        targetWeightKg: Double? = nil,
        note: String = "",
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.muscle = muscle
        self.sets = sets
        self.repsLow = repsLow
        self.repsHigh = repsHigh
        self.restSeconds = restSeconds
        self.targetWeightKg = targetWeightKg
        self.note = note
        self.order = order
    }

    var repsLabel: String {
        repsLow == repsHigh ? "\(repsLow)" : "\(repsLow)–\(repsHigh)"
    }
}

// MARK: - Workouts

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var date: Date = Date()
    var finishedAt: Date?
    var durationSeconds: Int = 0
    var activeStartedAt: Date?
    var isCompleted: Bool = false
    var title: String = ""
    var programName: String = ""
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(date: Date = Date(), title: String, programName: String) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.programName = programName
        self.activeStartedAt = nil
        self.exercises = []
    }

    var orderedExercises: [SessionExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var completedSets: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var totalVolume: Double {
        exercises.reduce(0) { partial, exercise in
            partial + exercise.sets
                .filter(\.isCompleted)
                .reduce(0) { $0 + $1.weightKg * Double($1.reps) }
        }
    }

    var durationLabel: String {
        let seconds = max(durationSeconds, 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours) ч \(minutes) мин" }
        return "\(max(minutes, 1)) мин"
    }

    func elapsedSeconds(at date: Date = Date()) -> Int {
        let active = activeStartedAt.map {
            max(0, Int(date.timeIntervalSince($0)))
        } ?? 0
        return durationSeconds + active
    }
}

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var name: String = ""
    var muscle: String = ""
    var order: Int = 0
    var restSeconds: Int = 90
    var note: String = ""
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.exercise)
    var sets: [SetEntry] = []

    init(name: String, muscle: String = "", order: Int = 0, restSeconds: Int = 90, note: String = "") {
        self.id = UUID()
        self.name = name
        self.muscle = muscle
        self.order = order
        self.restSeconds = restSeconds
        self.note = note
        self.sets = []
    }

    var orderedSets: [SetEntry] {
        sets.sorted { $0.order < $1.order }
    }
}

@Model
final class SetEntry {
    var id: UUID = UUID()
    var order: Int = 0
    var reps: Int = 8
    var weightKg: Double = 0
    var isCompleted: Bool = false
    var exercise: SessionExercise?

    init(order: Int = 0, reps: Int = 8, weightKg: Double = 0) {
        self.id = UUID()
        self.order = order
        self.reps = reps
        self.weightKg = weightKg
        self.isCompleted = false
    }
}

// MARK: - Progress

@Model
final class ProgressPhoto {
    var id: UUID = UUID()
    var date: Date = Date()
    var fileName: String = ""
    var weightKg: Double? = nil
    var note: String = ""
    var angleRaw: String = PhotoAngle.front.rawValue
    var createdAt: Date = Date()

    init(date: Date = Date(), fileName: String, weightKg: Double? = nil, note: String = "", angle: PhotoAngle = .front) {
        self.id = UUID()
        self.date = date
        self.fileName = fileName
        self.weightKg = weightKg
        self.note = note
        self.angleRaw = angle.rawValue
        self.createdAt = Date()
    }

    var angle: PhotoAngle {
        get { PhotoAngle(rawValue: angleRaw) ?? .front }
        set { angleRaw = newValue.rawValue }
    }

    var monthKey: String { WeekClock.monthKey(date) }
}

@Model
final class BodyMeasurement {
    var id: UUID = UUID()
    var date: Date = Date()
    var weightKg: Double = 0
    var bodyFat: Double? = nil
    var chestCm: Double? = nil
    var waistCm: Double? = nil
    var hipsCm: Double? = nil
    var armCm: Double? = nil
    var thighCm: Double? = nil
    var note: String = ""
    var createdAt: Date = Date()

    init(
        date: Date = Date(),
        weightKg: Double,
        bodyFat: Double? = nil,
        chestCm: Double? = nil,
        waistCm: Double? = nil,
        hipsCm: Double? = nil,
        armCm: Double? = nil,
        thighCm: Double? = nil,
        note: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.bodyFat = bodyFat
        self.chestCm = chestCm
        self.waistCm = waistCm
        self.hipsCm = hipsCm
        self.armCm = armCm
        self.thighCm = thighCm
        self.note = note
        self.createdAt = Date()
    }
}

// MARK: - Nutrition

@Model
final class FoodEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var createdAt: Date = Date()
    var name: String = ""
    var mealRaw: String = MealType.breakfast.rawValue
    var grams: Double? = nil
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0

    init(
        date: Date,
        name: String,
        meal: MealType,
        grams: Double? = nil,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = UUID()
        self.date = date
        self.createdAt = Date()
        self.name = name
        self.mealRaw = meal.rawValue
        self.grams = grams
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }

    var meal: MealType {
        get { MealType(rawValue: mealRaw) ?? .breakfast }
        set { mealRaw = newValue.rawValue }
    }
}

@Model
final class WaterLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var milliliters: Int = 250
    var createdAt: Date = Date()

    init(date: Date, milliliters: Int = 250) {
        self.id = UUID()
        self.date = date
        self.milliliters = milliliters
        self.createdAt = Date()
    }
}

// MARK: - Aggregations

struct NutritionTotals {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0

    init(entries: [FoodEntry]) {
        for entry in entries {
            calories += entry.calories
            protein += entry.protein
            carbs += entry.carbs
            fat += entry.fat
        }
    }

    init() {}
}
