//
//  EvaluateRecipeFeasibilityError.swift
//  FridgeFix
//

import Foundation

/// The one way asking "can I still make this?" can fail before any
/// pantry comparison even happens.
enum EvaluateRecipeFeasibilityError: LocalizedError, Equatable {
    /// The recipe has no ingredient requirements, so there is nothing for
    /// FridgeFix to compare against the pantry - a data problem with the
    /// recipe itself, not a pantry shortfall.
    case recipeHasNoIngredients

    var errorDescription: String? {
        switch self {
        case .recipeHasNoIngredients:
            return "This recipe does not contain any ingredients to evaluate. Choose another recipe."
        }
    }
}
