//
//  PantryItem.swift
//  PantryProof
//

import Foundation

/// An ``Ingredient`` and how much of it the cook currently has.
///
/// This is what's actually in the pantry, not what a recipe needs (that's
/// ``RecipeIngredient``). Kept as separate types on purpose - "what I have"
/// and "what the recipe wants" shouldn't get mixed up.
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
