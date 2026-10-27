import Foundation

/// A compact, offline food database. All values are per 100 g / 100 ml.
/// Keeping it local makes search instant and the app fully usable without network.
struct FoodItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: FoodCategory
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let defaultGrams: Double

    func calories(for grams: Double) -> Double {
        calories * grams / 100
    }

    func protein(for grams: Double) -> Double {
        protein * grams / 100
    }

    func carbs(for grams: Double) -> Double {
        carbs * grams / 100
    }

    func fat(for grams: Double) -> Double {
        fat * grams / 100
    }
}

enum FoodCategory: String, CaseIterable, Identifiable {
    case protein = "Белок"
    case carbs = "Углеводы"
    case vegetables = "Овощи"
    case fruit = "Фрукты"
    case dairy = "Молочное"
    case fats = "Жиры"
    case ready = "Готовое"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .protein: return "bolt.fill"
        case .carbs: return "square.stack.3d.up.fill"
        case .vegetables: return "leaf.fill"
        case .fruit: return "apple.logo"
        case .dairy: return "drop.fill"
        case .fats: return "circle.hexagongrid.fill"
        case .ready: return "fork.knife"
        }
    }
}

enum FoodDatabase {
    static let items: [FoodItem] = [
        // MARK: Белок
        item("chicken-breast", "Куриная грудка", .protein, kcal: 165, p: 31, c: 0, f: 3.6, grams: 180),
        item("turkey-fillet", "Индейка, филе", .protein, kcal: 150, p: 29, c: 0, f: 3.2, grams: 180),
        item("beef-90", "Говядина 10%", .protein, kcal: 176, p: 20, c: 0, f: 10, grams: 150),
        item("pork-loin", "Свинина, карбонад", .protein, kcal: 190, p: 24, c: 0, f: 10, grams: 150),
        item("salmon", "Лосось", .protein, kcal: 208, p: 20, c: 0, f: 13, grams: 150),
        item("tuna", "Тунец", .protein, kcal: 132, p: 28, c: 0, f: 1.3, grams: 150),
        item("eggs", "Яйцо куриное", .protein, kcal: 143, p: 12.6, c: 0.7, f: 9.5, grams: 110),
        item("cottage-5", "Творог 5%", .protein, kcal: 121, p: 17, c: 3, f: 5, grams: 180),
        item("cottage-0", "Творог 0%", .protein, kcal: 85, p: 18, c: 1.8, f: 0.4, grams: 180),
        item("greek-yogurt", "Греческий йогурт", .protein, kcal: 59, p: 10, c: 3.6, f: 0.4, grams: 170),
        item("whey", "Протеин, whey", .protein, kcal: 400, p: 80, c: 8, f: 4, grams: 30),
        item("shrimp", "Креветки", .protein, kcal: 99, p: 24, c: 0.2, f: 0.3, grams: 150),
        item("tofu", "Тофу", .protein, kcal: 76, p: 8, c: 1.9, f: 4.8, grams: 150),
        item("turkey-ham", "Ветчина из индейки", .protein, kcal: 104, p: 18, c: 1, f: 3, grams: 80),

        // MARK: Углеводы
        item("rice-white", "Рис белый, готовый", .carbs, kcal: 130, p: 2.7, c: 28, f: 0.3, grams: 200),
        item("rice-brown", "Рис бурый, готовый", .carbs, kcal: 123, p: 2.7, c: 25.6, f: 1, grams: 200),
        item("buckwheat", "Гречка, готовая", .carbs, kcal: 110, p: 4, c: 21, f: 1, grams: 200),
        item("oats", "Овсянка на воде", .carbs, kcal: 88, p: 3, c: 15, f: 1.7, grams: 250),
        item("pasta", "Макароны, готовые", .carbs, kcal: 131, p: 5, c: 25, f: 1.1, grams: 200),
        item("potato", "Картофель, варёный", .carbs, kcal: 82, p: 1.9, c: 17, f: 0.1, grams: 200),
        item("sweet-potato", "Батат", .carbs, kcal: 86, p: 1.6, c: 20, f: 0.1, grams: 200),
        item("bread", "Хлеб цельнозерновой", .carbs, kcal: 247, p: 13, c: 41, f: 3.4, grams: 60),
        item("tortilla", "Тортилья", .carbs, kcal: 310, p: 8, c: 50, f: 8, grams: 60),
        item("quinoa", "Киноа, готовая", .carbs, kcal: 120, p: 4.4, c: 21, f: 1.9, grams: 180),

        // MARK: Овощи
        item("cucumber", "Огурец", .vegetables, kcal: 15, p: 0.7, c: 3.6, f: 0.1, grams: 150),
        item("tomato", "Помидор", .vegetables, kcal: 18, p: 0.9, c: 3.9, f: 0.2, grams: 150),
        item("broccoli", "Брокколи", .vegetables, kcal: 34, p: 2.8, c: 6.6, f: 0.4, grams: 150),
        item("salad", "Салат микс", .vegetables, kcal: 17, p: 1.4, c: 2.9, f: 0.2, grams: 100),
        item("pepper", "Перец болгарский", .vegetables, kcal: 31, p: 1, c: 6, f: 0.3, grams: 150),
        item("avocado", "Авокадо", .vegetables, kcal: 160, p: 2, c: 8.5, f: 14.7, grams: 100),
        item("carrot", "Морковь", .vegetables, kcal: 41, p: 0.9, c: 9.6, f: 0.2, grams: 120),
        item("zucchini", "Кабачок", .vegetables, kcal: 17, p: 1.2, c: 3.1, f: 0.3, grams: 150),

        // MARK: Фрукты
        item("banana", "Банан", .fruit, kcal: 89, p: 1.1, c: 22.8, f: 0.3, grams: 120),
        item("apple", "Яблоко", .fruit, kcal: 52, p: 0.3, c: 14, f: 0.2, grams: 180),
        item("orange", "Апельсин", .fruit, kcal: 47, p: 0.9, c: 11.8, f: 0.1, grams: 180),
        item("blueberry", "Черника", .fruit, kcal: 57, p: 0.7, c: 14.5, f: 0.3, grams: 100),
        item("strawberry", "Клубника", .fruit, kcal: 32, p: 0.7, c: 7.7, f: 0.3, grams: 150),
        item("pear", "Груша", .fruit, kcal: 57, p: 0.4, c: 15, f: 0.1, grams: 180),

        // MARK: Молочное
        item("milk", "Молоко 2,5%", .dairy, kcal: 52, p: 2.8, c: 4.7, f: 2.5, grams: 250),
        item("kefir", "Кефир 1%", .dairy, kcal: 40, p: 3, c: 4, f: 1, grams: 250),
        item("cheese", "Сыр 45%", .dairy, kcal: 350, p: 25, c: 0, f: 27, grams: 40),
        item("mozzarella", "Моцарелла", .dairy, kcal: 280, p: 18, c: 3, f: 22, grams: 60),
        item("butter", "Масло сливочное", .dairy, kcal: 717, p: 0.9, c: 0.1, f: 81, grams: 10),

        // MARK: Жиры
        item("olive-oil", "Оливковое масло", .fats, kcal: 884, p: 0, c: 0, f: 100, grams: 10),
        item("almond", "Миндаль", .fats, kcal: 579, p: 21, c: 22, f: 50, grams: 30),
        item("walnut", "Грецкий орех", .fats, kcal: 654, p: 15, c: 14, f: 65, grams: 30),
        item("peanut-butter", "Арахисовая паста", .fats, kcal: 588, p: 25, c: 20, f: 50, grams: 30),
        item("sunflower-seeds", "Семечки", .fats, kcal: 584, p: 21, c: 20, f: 51, grams: 30),

        // MARK: Готовое
        item("plov", "Плов с курицей", .ready, kcal: 190, p: 8, c: 24, f: 7, grams: 250),
        item("pasta-chicken", "Паста с курицей", .ready, kcal: 165, p: 12, c: 18, f: 5, grams: 250),
        item("omelette", "Омлет из 2 яиц", .ready, kcal: 154, p: 11, c: 1.6, f: 11.5, grams: 200),
        item("syrniki", "Сырники", .ready, kcal: 220, p: 13, c: 25, f: 8, grams: 200),
        item("shawarma", "Шаурма с курицей", .ready, kcal: 215, p: 13, c: 22, f: 9, grams: 300),
        item("burger", "Бургер", .ready, kcal: 260, p: 13, c: 26, f: 12, grams: 220),
        item("chicken-soup", "Суп куриный", .ready, kcal: 42, p: 3.5, c: 4, f: 1.2, grams: 350),
        item("buckwheat-chicken", "Гречка с курицей", .ready, kcal: 145, p: 10, c: 17, f: 4, grams: 300),
        item("smoothie", "Смузи банан-йогурт", .ready, kcal: 75, p: 3, c: 14, f: 1, grams: 300),
        item("hummus", "Хумус", .ready, kcal: 166, p: 7.9, c: 14.3, f: 9.6, grams: 60)
    ]

    static func search(_ query: String) -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.category.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    static func items(in category: FoodCategory) -> [FoodItem] {
        items.filter { $0.category == category }
    }

    private static func item(
        _ id: String,
        _ name: String,
        _ category: FoodCategory,
        kcal: Double,
        p: Double,
        c: Double,
        f: Double,
        grams: Double
    ) -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            category: category,
            calories: kcal,
            protein: p,
            carbs: c,
            fat: f,
            defaultGrams: grams
        )
    }
}
