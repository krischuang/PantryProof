//
//  ShoppingListItem.swift
//  FridgeFix
//

import Foundation

/// An ingredient the home cook needs to buy, most often placed there
/// directly from a recipe's "Needs Attention" list rather than typed in by
/// hand.
///
/// Composition mirrors ``PantryItem``: a `ShoppingListItem` *has an*
/// ``Ingredient`` plus the quantity/unit context that only makes sense on a
/// shopping list — in this case, the amount the recipe that prompted the
/// addition actually needs, and whether the cook has picked it up yet.
struct ShoppingListItem: Identifiable, Hashable, Codable {
    let id: UUID
    var ingredient: Ingredient
    var quantity: Double
    var unit: MeasurementUnit
    var isCompleted: Bool

    init(id: UUID = UUID(), ingredient: Ingredient, quantity: Double, unit: MeasurementUnit, isCompleted: Bool = false) {
        self.id = id
        self.ingredient = ingredient
        self.quantity = quantity
        self.unit = unit
        self.isCompleted = isCompleted
    }

    var name: String { ingredient.name }

    var formattedQuantity: String { unit.formatted(quantity) }
}
