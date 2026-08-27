//
//  AddMissingIngredientToShoppingListError.swift
//  FridgeFix
//

import Foundation

/// The one way adding a recipe ingredient to the shopping list can fail.
enum AddMissingIngredientToShoppingListError: LocalizedError, Equatable {
    /// The required quantity is zero or negative — not a meaningful amount
    /// to put on a shopping list, and a sign the recipe requirement itself
    /// is malformed.
    case invalidRequiredQuantity

    var errorDescription: String? {
        switch self {
        case .invalidRequiredQuantity:
            return "The required amount for this ingredient is invalid, so it cannot be added to your shopping list."
        }
    }
}
