//
//  IngredientSubstitution.swift
//  FridgeFix
//

import Foundation

/// A usable stand-in for a recipe ingredient the cook does not have enough
/// of: `substitute` is confirmed to already be sitting in the pantry, so
/// suggesting it is something the cook can act on immediately rather than
/// a hypothetical swap that still requires a shopping trip.
///
/// FridgeFix only ever surfaces substitutions the pantry can already back
/// up. A substitution rule that names a candidate the cook does not have
/// is not useful information for deciding whether tonight's dinner is
/// possible, so it is filtered out before an `IngredientSubstitution` is
/// ever created — see `SubstitutionProviding`.
struct IngredientSubstitution: Identifiable, Hashable {
    var id: String { "\(original.id)->\(substitute.id)" }
    /// The recipe ingredient this substitution stands in for.
    let original: Ingredient
    /// The pantry ingredient that can be used instead.
    let substitute: Ingredient
}
