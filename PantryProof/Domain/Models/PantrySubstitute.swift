//
//  PantrySubstitute.swift
//  PantryProof
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
    /// Whether the pantry actually has *enough* of `substitute` to cover
    /// the original ingredient's required quantity.
    ///
    /// Existing in the pantry isn't the same as being enough - 1 ml of
    /// milk doesn't stand in for 100 ml of cream. Defaults to
    /// ``IngredientAvailability/quantityUnverified`` rather than
    /// ``IngredientAvailability/available``: a substitute with no
    /// quantity check behind it shouldn't be assumed sufficient.
    let quantityAvailability: IngredientAvailability

    init(original: Ingredient, substitute: Ingredient, quantityAvailability: IngredientAvailability = .quantityUnverified) {
        self.original = original
        self.substitute = substitute
        self.quantityAvailability = quantityAvailability
    }
}
