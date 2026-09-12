//
//  SubstitutionProviding.swift
//  FridgeFix
//

import Foundation

/// Suggests pantry-backed substitutes for a recipe ingredient the pantry
/// can't fully cover.
///
/// A protocol so `EvaluateRecipeFeasibilityUseCase` doesn't care how
/// substitution lookup works - `LocalSubstitutionService` is a small fixed
/// table for now, but it could be swapped for something bigger later.
protocol SubstitutionProviding {
    /// Substitutes for `ingredient` that are both a valid stand-in and
    /// actually in `pantry` right now.
    ///
    /// Implementations should never return a candidate the cook doesn't
    /// have - that's not useful information.
    func substitutions(for ingredient: Ingredient, availableIn pantry: [PantryItem]) -> [PantrySubstitute]
}
