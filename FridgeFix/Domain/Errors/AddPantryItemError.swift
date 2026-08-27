//
//  AddPantryItemError.swift
//  FridgeFix
//

import Foundation

/// Every way adding a pantry item can fail, each with a message written
/// for the home cook using the app — not a developer reading a log.
///
/// FridgeFix never surfaces a generic "invalid input" or "operation
/// failed" message: every case here explains what happened and, where
/// there's a sensible next step, what the cook can do about it.
enum AddPantryItemError: LocalizedError, Equatable {
    case emptyIngredientName
    case invalidQuantity

    var errorDescription: String? {
        switch self {
        case .emptyIngredientName:
            return "Please enter an ingredient name so FridgeFix knows what to add."
        case .invalidQuantity:
            return "Quantity must be zero or greater."
        }
    }
}
