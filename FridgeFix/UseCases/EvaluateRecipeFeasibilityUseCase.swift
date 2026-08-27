//
//  EvaluateRecipeFeasibilityUseCase.swift
//  FridgeFix
//

import Foundation

/// Answers FridgeFix's central question — "Can I still make this recipe?"
/// — by comparing a ``Recipe``'s requirements against the current pantry.
///
/// This is the primary business operation in FridgeFix. It is deliberately
/// a pure, deterministic function of its inputs — no persistence, no
/// randomness, no clock — so the same recipe and pantry combination always
/// produces the same ``RecipeEvaluation``. That determinism is what makes
/// the use case straightforward to unit test and safe for a view model to
/// call on demand, every time the pantry or the selected recipe changes.
struct EvaluateRecipeFeasibilityUseCase {
    /// Compares every ingredient `recipe` requires against `pantry`,
    /// ingredient by ingredient, and returns the resulting evaluation.
    ///
    /// Matching is by ``Ingredient/matches(_:)`` (case/whitespace-insensitive
    /// name equality) rather than identifier equality, since pantry items
    /// and recipe ingredients are independently-created `Ingredient`
    /// values that refer to the same food by name.
    func execute(recipe: Recipe, pantry: [PantryItem]) -> RecipeEvaluation {
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
                substitutions: []
            )
        }

        return RecipeIngredientEvaluation(
            recipeIngredient: recipeIngredient,
            pantryQuantity: pantryItem.quantity,
            pantryUnit: pantryItem.unit,
            availability: .available,
            substitutions: []
        )
    }
}
