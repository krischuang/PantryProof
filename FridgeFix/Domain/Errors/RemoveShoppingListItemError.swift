//
//  RemoveShoppingListItemError.swift
//  FridgeFix
//

import Foundation

/// The one way removing a shopping list item can fail.
enum RemoveShoppingListItemError: LocalizedError, Equatable {
    /// The item was already removed (e.g. by another action) before this
    /// removal could be applied.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "That item is no longer on your shopping list."
        }
    }
}
