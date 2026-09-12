//
//  PantrySubstitute.swift
//  FridgeFix
//

import Foundation

/// A stand-in for a recipe ingredient the cook doesn't have enough of.
///
/// `substitute` is always something already in the pantry - no point
/// suggesting a swap that still needs a shopping trip. See
/// `SubstitutionProviding` for where that check happens.
struct PantrySubstitute: Identifiable, Hashable {
    var id: String { "\(original.id)->\(substitute.id)" }
    /// The ingredient this substitution stands in for.
    let original: Ingredient
    /// The pantry ingredient to use instead.
    let substitute: Ingredient
}
