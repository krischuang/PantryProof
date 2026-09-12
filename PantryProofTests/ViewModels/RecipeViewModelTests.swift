//
//  RecipeViewModelTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

@MainActor
final class RecipeViewModelTests: XCTestCase {
    private func makeRecipe(ingredients: [RecipeIngredient]) -> Recipe {
        Recipe(name: "Test Recipe", summary: "A recipe used for testing.", ingredients: ingredients)
    }

    func test_evaluate_setsErrorMessage_whenRecipeHasNoIngredients() {
        let pantryRepository = InMemoryPantryRepository(seedItems: [])
        let viewModel = RecipeViewModel(pantryRepository: pantryRepository)
        let recipe = makeRecipe(ingredients: [])

        viewModel.evaluate(recipe)

        XCTAssertNil(viewModel.evaluation)
        XCTAssertEqual(viewModel.errorMessage, EvaluateRecipeFeasibilityError.recipeHasNoIngredients.errorDescription)
    }

    func test_feasibilityGuidance_namesUnverifiedIngredient_whenQuantityCannotBeCompared() {
        let butter = Ingredient(name: "Butter", category: .dairy)
        let pantryRepository = InMemoryPantryRepository(seedItems: [
            PantryItem(ingredient: butter, quantity: 500, unit: .grams)
        ])
        let viewModel = RecipeViewModel(pantryRepository: pantryRepository)
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: butter, quantity: 2, unit: .tablespoons, role: .essential)
        ])

        viewModel.evaluate(recipe)

        XCTAssertEqual(viewModel.evaluation?.feasibility, .canMakeWithAdjustments)
        let guidance = try? XCTUnwrap(viewModel.feasibilityGuidance)
        XCTAssertTrue(guidance?.contains("Butter") == true)
    }
}
