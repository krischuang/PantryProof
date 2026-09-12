//
//  SubstitutionProviding.swift
//  PantryProof
//

import Foundation

/// Suggests pantry-backed substitutes for a recipe ingredient the pantry
/// can't fully cover.
///
/// A protocol so `EvaluateRecipeFeasibilityUseCase` doesn't care how
/// substitution lookup works - `LocalSubstitutionService` is a small fixed
/// table for now, but it could be swapped for something bigger later.
protocol SubstitutionProviding {
    /// Substitutes for `recipeIngredient` that are both a valid stand-in
    /// and actually in `pantry` right now.
    ///
    /// Takes the full `RecipeIngredient`, not just its `Ingredient`,
    /// because a substitute's own quantity has to be checked against the
    /// same required amount - a substitute barely present in the pantry
    /// isn't a real substitute (see ``PantrySubstitute/quantityAvailability``).
    ///
    /// Implementations should never return a candidate the cook doesn't
    /// have - that's not useful information.
    func substitutions(for recipeIngredient: RecipeIngredient, availableIn pantry: [PantryItem]) -> [PantrySubstitute]
}
