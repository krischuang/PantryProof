//
//  MeasurementUnit.swift
//  FridgeFix
//

import Foundation

/// The unit a quantity is measured in - used by pantry stock, recipe
/// requirements, and shopping list entries.
///
/// A fixed set of units (not free text) so checking "same unit or not" is
/// an exact comparison. No conversion between units - 500 g vs. 2 cups is
/// out of scope, so FridgeFix never tries to guess.
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

    /// Formats a quantity for display, e.g. `500` -> `"500 g"`.
    ///
    /// One place for this so every screen formats quantities the same way.
    func formatted(_ quantity: Double) -> String {
        let isWholeNumber = quantity.truncatingRemainder(dividingBy: 1) == 0
        let value = isWholeNumber
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(value) \(symbol)"
    }
}
