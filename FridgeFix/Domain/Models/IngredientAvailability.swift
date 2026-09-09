//
//  IngredientAvailability.swift
//  FridgeFix
//

import Foundation

/// Whether a recipe ingredient is covered by what's currently in the
/// pantry, based on comparing required quantity vs. on-hand quantity.
///
/// Four states instead of a `Bool` because "have some, not enough" is a
/// different situation from "have none" - the cook can just buy more in
/// the first case. `quantityUnverified` is its own state too, since
/// guessing "available" when the units don't even match would be lying.
enum IngredientAvailability: Equatable, Hashable {
    /// Pantry has at least the required quantity, same unit as the recipe.
    case available
    /// In the pantry, same unit, just not enough of it.
    case insufficient
    /// Not in the pantry at all.
    case missing
    /// In the pantry, but in a different unit than the recipe uses, so we
    /// can't safely compare the two amounts.
    case quantityUnverified

    var displayName: String {
        switch self {
        case .available: return "Available"
        case .insufficient: return "Insufficient quantity"
        case .missing: return "Missing"
        case .quantityUnverified: return "Check amount"
        }
    }

    var symbolName: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .insufficient: return "exclamationmark.triangle.fill"
        case .missing: return "xmark.circle.fill"
        case .quantityUnverified: return "questionmark.circle.fill"
        }
    }
}
