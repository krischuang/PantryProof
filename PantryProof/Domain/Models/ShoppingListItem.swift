//
//  ShoppingListItem.swift
//  PantryProof
//

import Foundation

/// An ingredient the cook needs to buy - usually added straight from a
/// recipe's "Needs Attention" list rather than typed in by hand.
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
