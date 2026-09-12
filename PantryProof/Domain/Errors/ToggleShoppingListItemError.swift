//
//  ToggleShoppingListItemError.swift
//  PantryProof
//

import Foundation

/// The one way toggling a shopping list item's completion state can fail.
enum ToggleShoppingListItemError: LocalizedError, Equatable {
    /// Item was already removed by something else before the toggle could
    /// run.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "That item is no longer on your shopping list."
        }
    }
}
