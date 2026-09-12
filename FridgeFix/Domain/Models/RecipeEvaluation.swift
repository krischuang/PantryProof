//
//  RecipeEvaluation.swift
//  FridgeFix
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

    /// "500 g" style formatting of what's on hand, for the "Have / Need"
    /// comparison. `nil` if nothing is on hand.
    var formattedPantryQuantity: String? {
        guard let pantryQuantity, let pantryUnit else { return nil }
        return pantryUnit.formatted(pantryQuantity)
    }
}

/// The result of comparing a ``Recipe`` against the pantry - FridgeFix's
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
    /// - **Essential/replaceable, missing or short, no substitute**:
    ///   blocked. No point saying "can make with adjustments" if there's
    ///   no adjustment to offer.
    /// - **Essential/replaceable, missing or short, substitute exists**:
    ///   can make with adjustments.
    /// - **Essential/replaceable, quantity unverified**: never blocked
    ///   outright (it's in the pantry), but never ready to cook either
    ///   (the amount might be short) - always at least "adjustments".
    /// - **Optional**: never affects the verdict, whatever its state.
    var feasibility: RecipeFeasibility {
        let hasUnresolvedEssential = missingEssential.contains { $0.availability != .quantityUnverified && !$0.hasSubstitution }
        let hasUnresolvedReplaceable = missingReplaceable.contains { $0.availability != .quantityUnverified && !$0.hasSubstitution }
        if hasUnresolvedEssential || hasUnresolvedReplaceable {
            return .blocked
        }
        if !missingEssential.isEmpty || !missingReplaceable.isEmpty {
            return .canMakeWithAdjustments
        }
        return .readyToCook
    }
}
