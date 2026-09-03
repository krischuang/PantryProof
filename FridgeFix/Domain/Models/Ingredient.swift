//
//  Ingredient.swift
//  FridgeFix
//

import Foundation

/// Represents a food ingredient recognised by FridgeFix, such as "Chicken
/// Breast" or "Greek Yogurt".
///
/// `Ingredient` models identity only - a name and a broad category - with
/// no quantity or unit attached. A quantity only makes sense once an
/// ingredient is placed in a context: sitting in the pantry (`PantryItem`)
/// or required by a recipe (`RecipeIngredient`). Keeping `Ingredient` free
/// of that context lets the same ingredient concept be reused, and
/// compared, across both.
///
/// Ingredient identity is used consistently across pantry management,
/// substitution matching and recipe feasibility evaluation, so ``matches(_:)``
/// is the single place that decides whether two ingredients - typed by a
/// user, defined in a recipe, or suggested as a substitute - refer to the
/// same real-world food.
struct Ingredient: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var category: IngredientCategory

    init(id: UUID = UUID(), name: String, category: IngredientCategory = .other) {
        self.id = id
        self.name = name
        self.category = category
    }

    /// Whether two ingredients refer to the same real-world food, ignoring
    /// case and surrounding whitespace.
    ///
    /// A home cook typing "greek yogurt" while a recipe lists "Greek
    /// Yogurt" should count as a match - FridgeFix does not require exact
    /// string equality for something a user never sees as a raw string
    /// comparison.
    func matches(_ other: Ingredient) -> Bool {
        matches(name: other.name)
    }

    /// Whether this ingredient's name refers to the same real-world food as
    /// `otherName`, ignoring case and surrounding whitespace.
    func matches(name otherName: String) -> Bool {
        Self.normalized(name) == Self.normalized(otherName)
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// A broad grouping used to organise the pantry and to give ingredients a
/// recognisable icon in the UI.
///
/// This is presentation-adjacent, not a business rule: category never
/// affects recipe feasibility or substitution matching, both of which are
/// keyed on ``Ingredient/name`` only.
enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case grain = "Grain"
    case spice = "Spice & Condiment"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fork.knife"
        case .grain: return "square.grid.3x3.fill"
        case .spice: return "flame.fill"
        case .other: return "circle.grid.2x2.fill"
        }
    }
}
