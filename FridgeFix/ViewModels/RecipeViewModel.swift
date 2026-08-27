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
    /// ``evaluation`` for the recipe detail screen to render.
    func evaluate(_ recipe: Recipe) {
        evaluation = evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
    }

    /// A cheap, side-effect-free feasibility lookup for list-row badges —
    /// does not touch ``evaluation``, so browsing the recipe list never
    /// disturbs whatever evaluation the detail screen is currently
    /// showing.
    func feasibility(for recipe: Recipe) -> RecipeFeasibility {
        evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll()).feasibility
    }
}
