//
//  RecipeFeasibility.swift
//  FridgeFix
//

import Foundation

/// The overall "Can I still make this?" verdict for a recipe, given the
/// current pantry.
///
/// This is FridgeFix's headline answer, so it is modelled as its own type
/// rather than left as a combination of booleans the UI would otherwise
/// have to reconstruct (and could reconstruct inconsistently) itself. Every
/// screen and every test reads the same ``RecipeEvaluation/feasibility``
/// value, so the verdict shown to the cook can never contradict the
/// per-ingredient detail shown alongside it.
enum RecipeFeasibility: Equatable {
    /// Every ingredient the recipe needs is available in a sufficient
    /// quantity. Nothing stands between the cook and cooking.
    case readyToCook
    /// At least one essential or replaceable ingredient is missing or
    /// insufficient, but every such ingredient has a substitute available
    /// in the pantry (optional ingredients falling short never affect
    /// this).
    case canMakeWithAdjustments
    /// At least one essential or replaceable ingredient is missing or
    /// insufficient *and has no available substitute*. The recipe cannot
    /// reasonably proceed as written.
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
