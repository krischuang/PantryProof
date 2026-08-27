//
//  ToggleShoppingListItemError.swift
//  FridgeFix
//

import Foundation

/// The one way toggling a shopping list item's completion state can fail.
enum ToggleShoppingListItemError: LocalizedError, Equatable {
    /// The item was already removed (e.g. by another action) before the
    /// toggle could be applied.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "That item is no longer on your shopping list."
        }
    }
}
