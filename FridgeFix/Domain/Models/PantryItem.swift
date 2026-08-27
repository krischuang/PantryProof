//
//  PantryItem.swift
//  FridgeFix
//

import Foundation

/// A quantity of an ``Ingredient`` the home cook currently has on hand.
///
/// `PantryItem` is what FridgeFix compares a recipe's requirements
/// against to answer "can I still make this?" — it is the system's record
/// of reality (what's actually in the fridge/pantry), as opposed to
/// ``RecipeIngredient``, which is a recipe's *requirement*. The two are
/// deliberately separate types even though they share the same shape,
/// because a pantry quantity and a required quantity play different roles
/// in evaluation and must never be confused with one another.
struct PantryItem: Identifiable, Hashable, Codable {
    let id: UUID
    var ingredient: Ingredient
    var quantity: Double
    var unit: MeasurementUnit

    init(id: UUID = UUID(), ingredient: Ingredient, quantity: Double, unit: MeasurementUnit) {
        self.id = id
        self.ingredient = ingredient
        self.quantity = quantity
        self.unit = unit
    }

    var name: String { ingredient.name }

    var formattedQuantity: String { unit.formatted(quantity) }
}
