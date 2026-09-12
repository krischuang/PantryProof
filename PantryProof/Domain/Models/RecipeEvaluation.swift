//
//  RecipeEvaluation.swift
//  PantryProof
//

import Foundation

/// One recipe ingredient after being checked against the pantry: what's
/// needed, what's on hand, and any substitute if that's not enough.
struct RecipeIngredientEvaluation: Identifiable, Hashable {
    var id: UUID { recipeIngredient.id }
    let recipeIngredient: RecipeIngredient
    /// Quantity on hand. `nil` if the ingredient isn't in the pantry.
    let pantryQuantity: Double?
    /// The pantry's unit for this ingredient - may differ from the
    /// recipe's unit, which is why the quantities couldn't be compared.
    let pantryUnit: MeasurementUnit?
    let availability: IngredientAvailability
    /// Substitutes currently in the pantry. Empty when the ingredient is
    /// already available - no point suggesting a substitute you don't need.
    let substitutions: [PantrySubstitute]

    var ingredient: Ingredient { recipeIngredient.ingredient }
    var role: IngredientRole { recipeIngredient.role }
    var hasSubstitution: Bool { !substitutions.isEmpty }

    /// True when at least one substitute could plausibly cover this
    /// ingredient - either provably enough (``IngredientAvailability/available``)
    /// or not disprovable because the units differ
    /// (``IngredientAvailability/quantityUnverified``).
    ///
    /// A substitute that's demonstrably ``IngredientAvailability/insufficient``
    /// (same unit, not enough) doesn't count - it exists in the pantry, but
    /// it can't actually resolve the shortfall, so treating it as a fix
    /// would be false certainty.
    var hasUsableSubstitution: Bool {
        substitutions.contains { $0.quantityAvailability != .insufficient }
    }

    /// "500 g" style formatting of what's on hand, for the "Have / Need"
    /// comparison. `nil` if nothing is on hand.
    var formattedPantryQuantity: String? {
        guard let pantryQuantity, let pantryUnit else { return nil }
        return pantryUnit.formatted(pantryQuantity)
    }

    /// How much of this ingredient still needs to be bought to fully cover
    /// the recipe - not just the recipe's full requirement once some is
    /// already in the pantry.
    ///
    /// - ``IngredientAvailability/missing``: the full required quantity -
    ///   there's nothing on hand to subtract.
    /// - ``IngredientAvailability/insufficient``: only the shortage
    ///   (required minus on hand). Same unit is guaranteed here - that's
    ///   how it got marked insufficient in the first place - so the
    ///   subtraction is safe, and it's always strictly positive.
    /// - ``IngredientAvailability/quantityUnverified``: the full required
    ///   quantity. The units differ, so subtracting would be a guess, and
    ///   PantryProof doesn't guess at quantities.
    /// - ``IngredientAvailability/available``: zero - nothing to buy.
    var shoppingListQuantity: Double {
        switch availability {
        case .available:
            return 0
        case .missing, .quantityUnverified:
            return recipeIngredient.quantity
        case .insufficient:
            return max(recipeIngredient.quantity - (pantryQuantity ?? 0), 0)
        }
    }
}

/// The result of comparing a ``Recipe`` against the pantry - PantryProof's
/// answer to "can I still make this?".
///
/// One model instead of a bunch of booleans scattered around the view
/// layer, so every screen and test reads the same verdict.
struct RecipeEvaluation {
    let recipe: Recipe
    /// Every ingredient the recipe calls for, already compared against the
    /// pantry, in the recipe's own order.
    let evaluatedIngredients: [RecipeIngredientEvaluation]

    var availableIngredients: [RecipeIngredientEvaluation] {
        evaluatedIngredients.filter { $0.availability == .available }
    }

    var missingEssential: [RecipeIngredientEvaluation] { unresolved(role: .essential) }
    var missingReplaceable: [RecipeIngredientEvaluation] { unresolved(role: .replaceable) }
    var missingOptional: [RecipeIngredientEvaluation] { unresolved(role: .optional) }

    /// Everything not fully available, regardless of role - what the
    /// "Needs Attention" section shows.
    var missingIngredients: [RecipeIngredientEvaluation] {
        missingEssential + missingReplaceable + missingOptional
    }

    private func unresolved(role: IngredientRole) -> [RecipeIngredientEvaluation] {
        evaluatedIngredients.filter { $0.role == role && $0.availability != .available }
    }

    /// The one feasibility rule used everywhere - the UI, the tests, and
    /// this doc all agree on the same cases:
    ///
    /// - **Essential/replaceable, missing or short, no usable substitute**:
    ///   blocked. No point saying "can make with adjustments" if there's
    ///   no real adjustment to offer - a substitute that's itself
    ///   demonstrably insufficient doesn't count (see
    ///   ``RecipeIngredientEvaluation/hasUsableSubstitution``).
    /// - **Essential/replaceable, missing or short, usable substitute
    ///   exists**: can make with adjustments.
    /// - **Essential/replaceable, quantity unverified**: never blocked
    ///   outright (it's in the pantry), but never ready to cook either
    ///   (the amount might be short) - always at least "adjustments".
    /// - **Optional**: never affects the verdict, whatever its state.
    var feasibility: RecipeFeasibility {
        let hasUnresolvedEssential = missingEssential.contains { $0.availability != .quantityUnverified && !$0.hasUsableSubstitution }
        let hasUnresolvedReplaceable = missingReplaceable.contains { $0.availability != .quantityUnverified && !$0.hasUsableSubstitution }
        if hasUnresolvedEssential || hasUnresolvedReplaceable {
            return .blocked
        }
        if !missingEssential.isEmpty || !missingReplaceable.isEmpty {
            return .canMakeWithAdjustments
        }
        return .readyToCook
    }
}
