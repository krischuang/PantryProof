//
//  EvaluateRecipeFeasibilityUseCase.swift
//  PantryProof
//

import Foundation

/// Answers "can I still make this?" by comparing a ``Recipe``'s
/// requirements against the current pantry.
///
/// Pure function of its inputs - no persistence, no randomness - so the
/// same recipe + pantry always gives the same ``RecipeEvaluation``. Makes
/// it easy to test and safe to call again whenever the pantry changes.
struct EvaluateRecipeFeasibilityUseCase {
    private let substitutionProvider: SubstitutionProviding

    init(substitutionProvider: SubstitutionProviding = LocalSubstitutionService()) {
        self.substitutionProvider = substitutionProvider
    }

    /// Compares every ingredient `recipe` requires against `pantry` and
    /// returns the result.
    ///
    /// Matches ingredients by name (``Ingredient/matches(_:)``), not id -
    /// pantry items and recipe ingredients are created separately, so id
    /// equality would never match.
    ///
    /// - Throws: ``EvaluateRecipeFeasibilityError/recipeHasNoIngredients``
    ///   if `recipe` has no ingredient requirements to compare.
    func execute(recipe: Recipe, pantry: [PantryItem]) throws -> RecipeEvaluation {
        guard !recipe.ingredients.isEmpty else {
            throw EvaluateRecipeFeasibilityError.recipeHasNoIngredients
        }
        let evaluatedIngredients = recipe.ingredients.map { evaluate($0, against: pantry) }
        return RecipeEvaluation(recipe: recipe, evaluatedIngredients: evaluatedIngredients)
    }

    private func evaluate(_ recipeIngredient: RecipeIngredient, against pantry: [PantryItem]) -> RecipeIngredientEvaluation {
        guard let pantryItem = pantry.first(where: { $0.ingredient.matches(recipeIngredient.ingredient) }) else {
            return RecipeIngredientEvaluation(
                recipeIngredient: recipeIngredient,
                pantryQuantity: nil,
                pantryUnit: nil,
                availability: .missing,
                substitutions: substitutionProvider.substitutions(for: recipeIngredient, availableIn: pantry)
            )
        }

        let availability = IngredientAvailability.comparing(
            onHand: pantryItem.quantity,
            unit: pantryItem.unit,
            required: recipeIngredient.quantity,
            requiredUnit: recipeIngredient.unit
        )
        // Only bother looking up a substitute once the ingredient actually
        // falls short - no point checking for something already available.
        let substitutions = availability == .available
            ? []
            : substitutionProvider.substitutions(for: recipeIngredient, availableIn: pantry)

        return RecipeIngredientEvaluation(
            recipeIngredient: recipeIngredient,
            pantryQuantity: pantryItem.quantity,
            pantryUnit: pantryItem.unit,
            availability: availability,
            substitutions: substitutions
        )
    }
}
