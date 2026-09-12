//
//  RecipeFeasibility.swift
//  PantryProof
//

import Foundation

/// The overall "can I still make this?" verdict for a recipe.
///
/// One type instead of a pile of booleans, so every screen and test reads
/// the same verdict and nothing can show contradictory advice.
enum RecipeFeasibility: Equatable {
    /// Everything the recipe needs is available. Nothing stands in the way.
    case readyToCook
    /// Something essential/replaceable is missing or short, but there's a
    /// substitute for it (or its amount just couldn't be checked).
    case canMakeWithAdjustments
    /// Something essential/replaceable is missing or short with no
    /// substitute available. The recipe can't be made as written.
    case blocked

    var title: String {
        switch self {
        case .readyToCook: return "Ready to cook"
        case .canMakeWithAdjustments: return "Can make with adjustments"
        case .blocked: return "Missing required ingredients"
        }
    }

    var symbolName: String {
        switch self {
        case .readyToCook: return "checkmark.circle.fill"
        case .canMakeWithAdjustments: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.circle.fill"
        }
    }
}
