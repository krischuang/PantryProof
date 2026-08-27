//
//  UpdatePantryItemError.swift
//  FridgeFix
//

import Foundation

/// The one way updating a pantry item's quantity can fail beyond an
/// invalid quantity (which reuses ``AddPantryItemError/invalidQuantity``,
/// since it is exactly the same rule).
enum UpdatePantryItemError: LocalizedError, Equatable {
    /// The item was removed (e.g. from another screen) before the update
    /// could be applied.
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "That ingredient is no longer in your pantry."
        }
    }
}
