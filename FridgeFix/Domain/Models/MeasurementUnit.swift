//
//  MeasurementUnit.swift
//  FridgeFix
//

import Foundation

/// The unit a quantity is expressed in, shared by pantry stock, recipe
/// requirements and shopping list entries.
///
/// FridgeFix compares a recipe's required quantity against the pantry's
/// on-hand quantity to decide ``IngredientAvailability``. That comparison
/// is only meaningful when both sides are expressed in the *same* unit -
/// 500 g of flour cannot be safely compared to 2 cups without a reliable
/// conversion table, which is out of scope for FridgeFix's local,
/// deterministic evaluator. Modelling units as a fixed, closed set (rather
/// than free-text) is what makes "the same unit" a simple, exact
/// comparison instead of a fuzzy string match.
enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case grams = "g"
    case kilograms = "kg"
    case milliliters = "ml"
    case liters = "L"
    case pieces = "pcs"
    case cups = "cup"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"

    var id: String { rawValue }
    var symbol: String { rawValue }

    /// Formats a quantity for display, e.g. `500` → `"500 g"`, `1.5` →
    /// `"1.5 L"`.
    ///
    /// Centralised here so every screen that shows a quantity (pantry,
    /// recipe detail, shopping list) renders it identically instead of each
    /// view reimplementing its own `String(format:)` call.
    func formatted(_ quantity: Double) -> String {
        let isWholeNumber = quantity.truncatingRemainder(dividingBy: 1) == 0
        let value = isWholeNumber
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(value) \(symbol)"
    }
}
