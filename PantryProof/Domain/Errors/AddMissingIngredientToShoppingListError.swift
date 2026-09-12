//
//  AddMissingIngredientToShoppingListError.swift
//  PantryProof
//

import Foundation

/// The one way adding a recipe ingredient to the shopping list can fail.
enum AddMissingIngredientToShoppingListError: LocalizedError, Equatable {
    /// Quantity is zero or negative - not something you can put on a
    /// shopping list.
    case invalidRequiredQuantity

    var errorDescription: String? {
        switch self {
        case .invalidRequiredQuantity:
            return "The required amount for this ingredient is invalid, so it cannot be added to your shopping list."
        }
    }
}
