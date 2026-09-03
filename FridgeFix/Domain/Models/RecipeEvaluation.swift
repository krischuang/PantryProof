//
//  RecipeEvaluation.swift
//  FridgeFix
//

import Foundation

/// One recipe ingredient after being compared against the pantry: what the
/// recipe needs, what (if anything) the pantry currently has, and - once
/// that alone is not enough - what could stand in for it.
///
/// Composition mirrors the rest of the domain model: a
/// `RecipeIngredientEvaluation` *has a* ``RecipeIngredient`` plus the
/// pantry-comparison context that only exists once evaluation has run. This
/// lets a single list (available, insufficient and missing ingredients
/// together, in the recipe's own order) drive the recipe detail screen,
/// instead of the UI reassembling that context from several disconnected
/// arrays.
struct RecipeIngredientEvaluation: Identifiable, Hashable {
    var id: UUID { recipeIngredient.id }
    let recipeIngredient: RecipeIngredient
    /// Quantity currently on hand for this ingredient. `nil` when the
    /// ingredient is not in the pantry at all (`availability == .missing`).
    let pantryQuantity: Double?
    /// The pantry's own unit for this ingredient - may differ from
    /// `recipeIngredient.unit`, in which case the quantities were not
    /// directly comparable (see `EvaluateRecipeFeasibilityUseCase`).
    let pantryUnit: MeasurementUnit?
    let availability: IngredientAvailability
    /// Substitutes available right now in the pantry. Always empty when
    /// `availability == .available` - a substitute is only useful
    /// information once the ingredient itself falls short.
    let substitutions: [IngredientSubstitution]

    var ingredient: Ingredient { recipeIngredient.ingredient }
    var role: IngredientRole { recipeIngredient.role }
    var hasSubstitution: Bool { !substitutions.isEmpty }

    /// "500 g" style formatting of what's currently on hand, for a
    /// "Have / Need" comparison. `nil` when nothing is on hand at all.
    var formattedPantryQuantity: String? {
        guard let pantryQuantity, let pantryUnit else { return nil }
        return pantryUnit.formatted(pantryQuantity)
    }
}

/// The structured result of comparing a ``Recipe`` against the pantry -
/// FridgeFix's answer to "can I still make this?".
///
/// Grouping the outcome into one model, instead of several independent
/// booleans computed ad hoc in the view layer, means every screen, test and
/// piece of documentation reads the exact same ``feasibility`` value. All
/// of the comparison work (matching ingredients to pantry stock, looking up
/// substitutions) happens once, in `EvaluateRecipeFeasibilityUseCase`; this
/// type only derives the final verdict from that already-computed detail,
/// which keeps the rule itself pure, dependency-free and easy to unit test.
struct RecipeEvaluation {
    let recipe: Recipe
    /// Every ingredient the recipe calls for, each already compared
    /// against the pantry, in the recipe's own ingredient order.
    let evaluatedIngredients: [RecipeIngredientEvaluation]

    var availableIngredients: [RecipeIngredientEvaluation] {
        evaluatedIngredients.filter { $0.availability == .available }
    }

    var missingEssential: [RecipeIngredientEvaluation] { unresolved(role: .essential) }
    var missingReplaceable: [RecipeIngredientEvaluation] { unresolved(role: .replaceable) }
    var missingOptional: [RecipeIngredientEvaluation] { unresolved(role: .optional) }

    /// Every ingredient that is not fully available, regardless of role -
    /// what the recipe detail screen's "Needs Attention" section renders.
    var missingIngredients: [RecipeIngredientEvaluation] {
        missingEssential + missingReplaceable + missingOptional
    }

    private func unresolved(role: IngredientRole) -> [RecipeIngredientEvaluation] {
        evaluatedIngredients.filter { $0.role == role && $0.availability != .available }
    }

    /// The single, consistent feasibility rule used everywhere FridgeFix
    /// answers "can I still make this?" - the UI, the unit tests and this
    /// documentation all describe the same cases:
    ///
    /// - **Essential or replaceable**, missing or insufficient, **with no
    ///   substitution available**: blocks the recipe. A replaceable
    ///   ingredient the cook can neither buy nor swap out is exactly as
    ///   blocking as an essential one - FridgeFix never tells the cook
    ///   "can make with adjustments" while also having no adjustment to
    ///   offer.
    /// - **Essential or replaceable**, missing or insufficient, **with a
    ///   substitution available**: the recipe can still be made with
    ///   adjustments.
    /// - **Essential or replaceable**, with a ``IngredientAvailability/quantityUnverified``
    ///   amount: never blocks the recipe outright - the ingredient's
    ///   *presence* is confirmed, only its quantity is in question, so
    ///   treating it the same as a genuinely missing ingredient would be
    ///   too harsh. But it can never result in ``RecipeFeasibility/readyToCook``
    ///   either, since the amount on hand genuinely might be short.
    ///   FridgeFix always downgrades this to at least
    ///   ``RecipeFeasibility/canMakeWithAdjustments``, so the cook is asked
    ///   to check the amount before treating the recipe as ready.
    /// - **Optional**, missing, insufficient, or quantity-unverified: never
    ///   affects feasibility, by definition of what "optional" means in
    ///   FridgeFix.
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
