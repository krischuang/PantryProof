//
//  RemoveShoppingListItemError.swift
//  PantryProof
//

import Foundation

/// The one way removing a shopping list item can fail.
enum RemoveShoppingListItemError: LocalizedError, Equatable {
    /// Item was already removed by something else before this could run.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "That item is no longer on your shopping list."
        }
    }
}
