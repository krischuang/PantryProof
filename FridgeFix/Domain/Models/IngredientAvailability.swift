//
//  IngredientAvailability.swift
//  FridgeFix
//

import Foundation

/// Whether a recipe's required ingredient is covered by what is currently
/// in the pantry, as decided by comparing a ``RecipeIngredient``'s
/// required quantity against the matching ``PantryItem``'s on-hand
/// quantity.
///
/// Modelled as four states rather than a `Bool` because "have some, but
/// not enough" is a materially different situation from "have none at
/// all" — a cook with 200 g of chicken for a 400 g requirement can decide
/// to buy 200 g more, whereas a cook with none needs to think about the
/// ingredient from scratch. Collapsing both into a single "missing" state
/// would throw away information the recipe detail screen needs to show a
/// useful "Have / Need" comparison. ``quantityUnverified`` exists for the
/// same reason: it is a materially different situation from both
/// ``available`` and ``insufficient``, and collapsing it into either would
/// mean FridgeFix claiming a certainty about quantity it cannot actually
/// back up.
enum IngredientAvailability: Equatable, Hashable {
    /// The pantry holds at least the required quantity, in the same unit
    /// the recipe specifies.
    case available
    /// The ingredient is in the pantry, in the same unit the recipe
    /// specifies, but in a smaller quantity than required.
    case insufficient
    /// The ingredient does not appear in the pantry at all.
    case missing
    /// The ingredient is in the pantry, but in a different
    /// ``MeasurementUnit`` than the recipe requires, so the quantities
    /// cannot be safely compared without an unreliable conversion.
    /// FridgeFix never guesses here — it surfaces the pantry's own
    /// quantity and asks the cook to judge it themselves rather than
    /// silently reporting ``available`` or ``insufficient``.
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
