//
//  EvaluateRecipeFeasibilityError.swift
//  FridgeFix
//

import Foundation

/// The one way evaluating a recipe can fail before any pantry comparison
/// even happens.
enum EvaluateRecipeFeasibilityError: LocalizedError, Equatable {
    /// Recipe has no ingredients to compare - a problem with the recipe
    /// data, not the pantry.
    case recipeHasNoIngredients

    var errorDescription: String? {
        switch self {
        case .recipeHasNoIngredients:
            return "This recipe does not contain any ingredients to evaluate. Choose another recipe."
        }
    }
}
