//
//  RecipeViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for browsing recipes and asking
/// FridgeFix's central question — "can I still make this?" — about one of
/// them.
///
/// `RecipeViewModel` never compares ingredients or decides feasibility
/// itself; every evaluation is delegated to
/// ``EvaluateRecipeFeasibilityUseCase``, called against the pantry's
/// current contents at the moment of evaluation so the answer always
/// reflects the latest pantry state.
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

    /// Runs the full evaluation for `recipe` and stores it in
    /// ``evaluation`` for the recipe detail screen to render. On failure
    /// (the recipe has no ingredients), ``errorMessage`` is set instead.
    func evaluate(_ recipe: Recipe) {
        errorMessage = nil
        do {
            evaluation = try evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        } catch {
            evaluation = nil
            errorMessage = error.localizedDescription
        }
    }

    /// A cheap, side-effect-free feasibility lookup for list-row badges —
    /// does not touch ``evaluation``, so browsing the recipe list never
    /// disturbs whatever evaluation the detail screen is currently
    /// showing.
    ///
    /// A recipe with no ingredients cannot be evaluated at all; `.blocked`
    /// is the safe default badge for that case, consistent with FridgeFix
    /// never claiming readiness it cannot back up.
    func feasibility(for recipe: Recipe) -> RecipeFeasibility {
        let evaluation = try? evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        return evaluation?.feasibility ?? .blocked
    }
}
