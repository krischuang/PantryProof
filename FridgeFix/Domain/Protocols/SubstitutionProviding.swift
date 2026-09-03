//
//  SubstitutionProviding.swift
//  FridgeFix
//

import Foundation

/// A domain service that suggests pantry-backed substitutes for a recipe
/// ingredient the pantry cannot fully cover.
///
/// Abstracted as a protocol so ``EvaluateRecipeFeasibilityUseCase`` depends
/// on *what* substitution lookup does, not *how* it is implemented. The
/// concrete `LocalSubstitutionService` is a small, deterministic, offline
/// lookup table appropriate for FridgeFix's current scope, but neither the
/// use case nor its tests need to know that - a future implementation
/// (a larger rules table, a server-backed lookup) could be substituted in
/// without changing the feasibility rule at all.
protocol SubstitutionProviding {
    /// Every substitute for `ingredient` that is both a sanctioned
    /// stand-in for it and currently sitting in `pantry`.
    ///
    /// A substitution rule naming a candidate the cook does not have is
    /// not useful information for deciding whether tonight's dinner is
    /// possible, so implementations must never return a candidate that
    /// fails the pantry check.
    func substitutions(for ingredient: Ingredient, availableIn pantry: [PantryItem]) -> [IngredientSubstitution]
}
