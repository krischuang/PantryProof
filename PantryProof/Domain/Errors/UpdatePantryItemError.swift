//
//  UpdatePantryItemError.swift
//  PantryProof
//

import Foundation

/// Every way updating a pantry item can fail.
enum UpdatePantryItemError: LocalizedError, Equatable {
    /// The new quantity is negative.
    case invalidQuantity
    /// Item was removed elsewhere before the update could apply.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .invalidQuantity:
            return "Quantity must be zero or greater."
        case .itemNotFound:
            return "That ingredient is no longer in your pantry."
        }
    }
}
