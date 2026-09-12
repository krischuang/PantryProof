//
//  RecipeViewModel.swift
//  PantryProof
//

import Foundation
import Observation

/// Presentation state and actions for browsing recipes and asking "can I
/// still make this?" about one of them.
///
/// Never computes feasibility itself - that's all
/// ``EvaluateRecipeFeasibilityUseCase``. This just turns the result into
/// display-ready text (``feasibilityGuidance``) so the view doesn't have
/// to interpret a `RecipeEvaluation` on its own.
@MainActor
@Observable
final class RecipeViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var evaluation: RecipeEvaluation?
    var errorMessage: String?

    private let recipeRepository: RecipeRepository
    private let pantryRepository: PantryRepository
    private let evaluateFeasibilityUseCase: EvaluateRecipeFeasibilityUseCase

    init(
        recipeRepository: RecipeRepository = InMemoryRecipeRepository(),
        pantryRepository: PantryRepository,
        evaluateFeasibilityUseCase: EvaluateRecipeFeasibilityUseCase = EvaluateRecipeFeasibilityUseCase()
    ) {
        self.recipeRepository = recipeRepository
        self.pantryRepository = pantryRepository
        self.evaluateFeasibilityUseCase = evaluateFeasibilityUseCase
        loadRecipes()
    }

    func loadRecipes() {
        recipes = recipeRepository.fetchAll()
    }

    /// Evaluates `recipe` and stores the result in ``evaluation``. On
    /// failure (no ingredients), sets ``errorMessage`` instead.
    func evaluate(_ recipe: Recipe) {
        errorMessage = nil
        do {
            evaluation = try evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        } catch {
            evaluation = nil
            errorMessage = error.localizedDescription
        }
    }

    /// Quick feasibility lookup for list-row badges. Doesn't touch
    /// ``evaluation``, so browsing the list doesn't disturb whatever the
    /// detail screen is currently showing.
    ///
    /// Recipes with no ingredients can't be evaluated, so they default to
    /// `.blocked` rather than claiming readiness we can't back up.
    func feasibility(for recipe: Recipe) -> RecipeFeasibility {
        let evaluation = try? evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        return evaluation?.feasibility ?? .blocked
    }

    /// One sentence of guidance for the current evaluation's verdict,
    /// derived from the same evaluation so the wording can't contradict
    /// the ingredient list next to it. `nil` if there's nothing to show.
    var feasibilityGuidance: String? {
        guard let evaluation else { return nil }
        switch evaluation.feasibility {
        case .readyToCook:
            return "Everything this recipe needs is already in your pantry."
        case .canMakeWithAdjustments:
            return adjustmentGuidance(for: evaluation)
        case .blocked:
            return blockedGuidance(for: evaluation)
        }
    }

    private func adjustmentGuidance(for evaluation: RecipeEvaluation) -> String {
        let unresolved = evaluation.missingEssential + evaluation.missingReplaceable
        let substitutable = unresolved.filter { $0.hasSubstitution }.map(\.ingredient.name)
        let unverified = unresolved.filter { $0.availability == .quantityUnverified && !$0.hasSubstitution }.map(\.ingredient.name)

        var sentences: [String] = []
        if !substitutable.isEmpty {
            sentences.append("Use a substitute for \(substitutable.joined(separator: ", ")) - see the ingredient list below.")
        }
        if !unverified.isEmpty {
            sentences.append("Check the amount of \(unverified.joined(separator: ", ")) before cooking - PantryProof couldn't compare its unit to what the recipe needs.")
        }
        return sentences.joined(separator: " ")
    }

    private func blockedGuidance(for evaluation: RecipeEvaluation) -> String {
        let unresolved = evaluation.missingIngredients.filter { !$0.hasSubstitution && $0.role != .optional }
        let names = unresolved.map(\.ingredient.name)
        return "\(names.joined(separator: ", ")) - no substitute available. Add to your shopping list below."
    }
}
