//
//  RemovePantryItemError.swift
//  FridgeFix
//

import Foundation

/// The one way removing a pantry item can fail.
enum RemovePantryItemError: LocalizedError, Equatable {
    /// The item was already removed (e.g. by another action) before this
    /// removal could be applied.
    case pantryItemNotFound

    var errorDescription: String? {
        switch self {
        case .pantryItemNotFound:
            return "That ingredient is no longer in your pantry."
        }
    }
}
