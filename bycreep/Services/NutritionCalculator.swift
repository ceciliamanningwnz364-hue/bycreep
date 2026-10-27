import Foundation

struct NutritionPlan: Equatable {
    let bmr: Double
    let tdee: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let waterML: Double
    let weeklyChangeKg: Double

    var proteinCalories: Double { protein * 4 }
    var carbsCalories: Double { carbs * 4 }
    var fatCalories: Double { fat * 9 }
}

enum NutritionCalculator {
    /// Mifflin–St Jeor.
    static func bmr(sex: Sex, weightKg: Double, heightCm: Double, age: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return max(0, sex == .male ? base + 5 : base - 161)
    }

    static func tdee(for profile: UserProfile) -> Double {
        bmr(
            sex: profile.sex,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age
        ) * profile.activity.multiplier
    }

    static func plan(for profile: UserProfile) -> NutritionPlan {
        let bmr = bmr(
            sex: profile.sex,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age
        )
        let tdee = bmr * profile.activity.multiplier

        let minimumCalories: Double = profile.sex == .male ? 1500 : 1250
        let adjusted = tdee * (1 + profile.goal.calorieAdjustment)
        let calories = max(adjusted, bmr * 1.05, minimumCalories).roundedToNearest(10)

        let protein = min(
            profile.weightKg * profile.goal.proteinPerKg,
            calories * 0.40 / 4
        ).roundedToNearest(5)
        let fat = min(
            profile.weightKg * 0.9,
            calories * 0.30 / 9
        ).roundedToNearest(5)

        // Keep protein and fat inside the calorie budget at high body weights
        // and low calorie targets; carbs fill the remainder.
        let carbCalories = max(calories - protein * 4 - fat * 9, 0)
        let carbs = max((carbCalories / 4 / 5).rounded(.down) * 5, 40)

        let water = (profile.weightKg * 35 + 500).roundedToNearest(50)
        let weeklyChange = (calories - tdee) * 7 / 7700

        return NutritionPlan(
            bmr: bmr.rounded(),
            tdee: tdee.rounded(),
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            waterML: water,
            weeklyChangeKg: weeklyChange
        )
    }

    static func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Недостаток"
        case 18.5..<25: return "Норма"
        case 25..<30: return "Избыток"
        default: return "Ожирение"
        }
    }
}

extension Double {
    func roundedToNearest(_ step: Double) -> Double {
        guard step > 0 else { return self }
        return (self / step).rounded() * step
    }
}
