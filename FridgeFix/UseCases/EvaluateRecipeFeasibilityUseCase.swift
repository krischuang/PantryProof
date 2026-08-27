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
    private let substitutionProvider: SubstitutionProviding

    init(substitutionProvider: SubstitutionProviding = LocalSubstitutionService()) {
        self.substitutionProvider = substitutionProvider
    }

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
                substitutions: substitutionProvider.substitutions(for: recipeIngredient.ingredient, availableIn: pantry)
            )
        }

        let availability = availability(of: pantryItem, comparedTo: recipeIngredient)
        // A substitute is only useful information once the ingredient
        // itself falls short — looking one up for an already-available
        // ingredient would be wasted work and dead data on every row.
        let substitutions = availability == .available
            ? []
            : substitutionProvider.substitutions(for: recipeIngredient.ingredient, availableIn: pantry)

        return RecipeIngredientEvaluation(
            recipeIngredient: recipeIngredient,
            pantryQuantity: pantryItem.quantity,
            pantryUnit: pantryItem.unit,
            availability: availability,
            substitutions: substitutions
        )
    }

    /// Quantity-aware availability for an ingredient already confirmed to
    /// be in the pantry:
    ///
    /// - pantry quantity >= required quantity → ``IngredientAvailability/available``
    /// - pantry quantity < required quantity → ``IngredientAvailability/insufficient``
    ///
    /// **Deliberately no unit conversion.** Quantities are compared
    /// directly only when the pantry and recipe already use the exact same
    /// ``MeasurementUnit`` case. When the units genuinely differ (e.g. the
    /// recipe wants tablespoons of butter and the pantry has it in grams),
    /// converting between them reliably would require a real
    /// measurement-conversion engine — ingredient density, package
    /// rounding, and so on — which is out of scope for FridgeFix. Rather
    /// than invent an unreliable conversion that could tell the cook the
    /// wrong thing, FridgeFix falls back to the ingredient's mere presence
    /// in the pantry and leaves the pantry's own quantity visible in the UI
    /// so the cook can judge for themselves.
    private func availability(of pantryItem: PantryItem, comparedTo recipeIngredient: RecipeIngredient) -> IngredientAvailability {
        guard pantryItem.unit == recipeIngredient.unit else {
            return .available
        }
        return pantryItem.quantity >= recipeIngredient.quantity ? .available : .insufficient
    }
}
