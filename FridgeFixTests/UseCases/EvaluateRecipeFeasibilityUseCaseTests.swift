//
//  EvaluateRecipeFeasibilityUseCaseTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

/// A substitution provider whose answers are fixed in advance, so tests can
/// control exactly which ingredients have a usable substitute without
/// depending on `LocalSubstitutionService`'s specific rule table.
private struct StubSubstitutionProvider: SubstitutionProviding {
    var substitutionsByIngredientName: [String: [IngredientSubstitution]] = [:]

    func substitutions(for ingredient: Ingredient, availableIn pantry: [PantryItem]) -> [IngredientSubstitution] {
        substitutionsByIngredientName[ingredient.name.lowercased()] ?? []
    }
}

final class EvaluateRecipeFeasibilityUseCaseTests: XCTestCase {
    private func makeIngredient(_ name: String) -> Ingredient {
        Ingredient(name: name)
    }

    private func makeRecipe(ingredients: [RecipeIngredient]) -> Recipe {
        Recipe(name: "Test Recipe", summary: "A recipe used for testing.", ingredients: ingredients)
    }

    // MARK: - Quantity-aware availability

    func test_evaluateRecipe_reportsAvailable_whenPantryQuantityExactlyMeetsRequirement() throws {
        let chicken = makeIngredient("Chicken")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: chicken, quantity: 400, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.evaluatedIngredients.first?.availability, .available)
    }

    func test_evaluateRecipe_reportsAvailable_whenPantryQuantityExceedsRequirement() throws {
        let chicken = makeIngredient("Chicken")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: chicken, quantity: 600, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.evaluatedIngredients.first?.availability, .available)
    }

    func test_evaluateRecipe_reportsInsufficient_whenPantryQuantityIsBelowRequirement() throws {
        let chicken = makeIngredient("Chicken")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: chicken, quantity: 200, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        let evaluatedChicken = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedChicken?.availability, .insufficient)
        XCTAssertEqual(evaluatedChicken?.pantryQuantity, 200)
    }

    func test_evaluateRecipe_reportsMissing_whenIngredientIsNotInPantry() throws {
        let chicken = makeIngredient("Chicken")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential)
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: [])

        let evaluatedChicken = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedChicken?.availability, .missing)
        XCTAssertNil(evaluatedChicken?.pantryQuantity)
    }

    func test_evaluateRecipe_marksQuantityUnverified_whenPantryAndRecipeUnitsDiffer() throws {
        let butter = makeIngredient("Butter")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: butter, quantity: 2, unit: .tablespoons, role: .essential)
        ])
        // Pantry holds butter by weight, not by the tablespoon — units are
        // not directly comparable, so FridgeFix must not silently claim
        // the quantity is sufficient.
        let pantry = [PantryItem(ingredient: butter, quantity: 5, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.evaluatedIngredients.first?.availability, .quantityUnverified)
    }

    func test_evaluateRecipe_doesNotReportReadyToCook_whenEssentialQuantityCannotBeVerified() throws {
        let butter = makeIngredient("Butter")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: butter, quantity: 2, unit: .tablespoons, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: butter, quantity: 500, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        // Presence is confirmed but the amount is not, so FridgeFix must
        // never claim "ready to cook" — but it also must not block the
        // recipe outright, since the ingredient genuinely is in the
        // pantry.
        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    // MARK: - Role-driven blocking

    func test_evaluateRecipe_blocksCooking_whenEssentialIngredientIsMissingWithNoSubstitute() throws {
        let chicken = makeIngredient("Chicken")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential)
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: [])

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_evaluateRecipe_allowsAdjustments_whenEssentialIngredientMissingButSubstituteExists() throws {
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: milk, quantity: 500, unit: .milliliters)]
        let substitutionProvider = StubSubstitutionProvider(substitutionsByIngredientName: [
            "cream": [IngredientSubstitution(original: cream, substitute: milk)]
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: substitutionProvider)
            .execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_evaluateRecipe_blocksCooking_whenReplaceableIngredientIsMissingWithNoSubstitute() throws {
        let parmesan = makeIngredient("Parmesan")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: parmesan, quantity: 50, unit: .grams, role: .replaceable)
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: [])

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_evaluateRecipe_allowsAdjustments_whenReplaceableIngredientHasSubstituteAvailable() throws {
        let parmesan = makeIngredient("Parmesan")
        let cheddar = makeIngredient("Cheddar")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: parmesan, quantity: 50, unit: .grams, role: .replaceable)
        ])
        let pantry = [PantryItem(ingredient: cheddar, quantity: 200, unit: .grams)]
        let substitutionProvider = StubSubstitutionProvider(substitutionsByIngredientName: [
            "parmesan": [IngredientSubstitution(original: parmesan, substitute: cheddar)]
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: substitutionProvider)
            .execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_evaluateRecipe_doesNotBlockCooking_whenOptionalIngredientIsMissing() throws {
        let chicken = makeIngredient("Chicken")
        let garnish = makeIngredient("Parsley")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential),
            RecipeIngredient(ingredient: garnish, quantity: 1, unit: .tablespoons, role: .optional)
        ])
        let pantry = [PantryItem(ingredient: chicken, quantity: 400, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .readyToCook)
    }

    // MARK: - Overall feasibility

    func test_evaluateRecipe_isReadyToCook_whenAllIngredientsAreFullyAvailable() throws {
        let chicken = makeIngredient("Chicken")
        let rice = makeIngredient("Rice")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential),
            RecipeIngredient(ingredient: rice, quantity: 200, unit: .grams, role: .essential)
        ])
        let pantry = [
            PantryItem(ingredient: chicken, quantity: 400, unit: .grams),
            PantryItem(ingredient: rice, quantity: 500, unit: .grams)
        ]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .readyToCook)
    }

    func test_evaluateRecipe_isBlocked_whenMixedAvailabilityIncludesAnUnresolvedEssential() throws {
        let chicken = makeIngredient("Chicken")
        let rice = makeIngredient("Rice")
        let garnish = makeIngredient("Parsley")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential),
            RecipeIngredient(ingredient: rice, quantity: 200, unit: .grams, role: .essential),
            RecipeIngredient(ingredient: garnish, quantity: 1, unit: .tablespoons, role: .optional)
        ])
        // Rice is available and the optional garnish is missing (fine on
        // its own), but chicken — essential — is missing with no
        // substitute, so the overall recipe must still be blocked.
        let pantry = [PantryItem(ingredient: rice, quantity: 500, unit: .grams)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    // MARK: - Malformed recipes

    func test_evaluateRecipe_fails_whenRecipeContainsNoIngredients() {
        let recipe = makeRecipe(ingredients: [])

        XCTAssertThrowsError(try EvaluateRecipeFeasibilityUseCase().execute(recipe: recipe, pantry: [])) { error in
            XCTAssertEqual(error as? EvaluateRecipeFeasibilityError, .recipeHasNoIngredients)
        }
    }
}
