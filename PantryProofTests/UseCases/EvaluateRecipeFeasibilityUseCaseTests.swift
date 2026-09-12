//
//  EvaluateRecipeFeasibilityUseCaseTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

/// Fake substitution provider so tests can control exactly which
/// ingredients have a substitute, without depending on
/// `LocalSubstitutionService`'s actual rules.
private struct StubSubstitutionProvider: SubstitutionProviding {
    var substitutionsByIngredientName: [String: [PantrySubstitute]] = [:]

    func substitutions(for recipeIngredient: RecipeIngredient, availableIn pantry: [PantryItem]) -> [PantrySubstitute] {
        substitutionsByIngredientName[recipeIngredient.ingredient.name.lowercased()] ?? []
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
        // Pantry has grams, recipe wants tablespoons - can't compare directly.
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

        // It's in the pantry, just can't verify the amount - not ready,
        // not blocked.
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
            "cream": [PantrySubstitute(original: cream, substitute: milk)]
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
            "parmesan": [PantrySubstitute(original: parmesan, substitute: cheddar)]
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: substitutionProvider)
            .execute(recipe: recipe, pantry: pantry)

        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_evaluateRecipe_allowsAdjustments_whenEssentialIngredientIsInsufficientButSubstituteAvailable() throws {
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])
        // Cream is in the pantry but short of what the recipe needs - not
        // missing, just insufficient - and Milk covers it.
        let pantry = [
            PantryItem(ingredient: cream, quantity: 30, unit: .milliliters),
            PantryItem(ingredient: milk, quantity: 500, unit: .milliliters)
        ]
        let substitutionProvider = StubSubstitutionProvider(substitutionsByIngredientName: [
            "cream": [PantrySubstitute(original: cream, substitute: milk)]
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: substitutionProvider)
            .execute(recipe: recipe, pantry: pantry)

        let evaluatedCream = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedCream?.availability, .insufficient)
        XCTAssertTrue(evaluatedCream?.hasSubstitution == true)
        // Insufficient, not missing, but the substitute still means this
        // isn't blocking - same rule as a missing ingredient with a
        // substitute.
        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    // MARK: - Substitute quantity certainty

    func test_evaluateRecipe_allowsAdjustments_whenSubstituteQuantityClearlyCoversRequirement() throws {
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])
        let pantry = [PantryItem(ingredient: milk, quantity: 500, unit: .milliliters)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: LocalSubstitutionService())
            .execute(recipe: recipe, pantry: pantry)

        let evaluatedCream = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedCream?.substitutions.first?.quantityAvailability, .available)
        XCTAssertTrue(evaluatedCream?.hasUsableSubstitution == true)
        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_evaluateRecipe_blocksCooking_whenTheOnlySubstituteInPantryIsClearlyInsufficient() throws {
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])
        // Milk is a valid substitute in principle, but 1 ml doesn't stand
        // in for 100 ml - existing in the pantry isn't the same as being
        // enough, so this must not read as a confident fix.
        let pantry = [PantryItem(ingredient: milk, quantity: 1, unit: .milliliters)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: LocalSubstitutionService())
            .execute(recipe: recipe, pantry: pantry)

        let evaluatedCream = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedCream?.substitutions.first?.quantityAvailability, .insufficient)
        XCTAssertFalse(evaluatedCream?.hasUsableSubstitution == true)
        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_evaluateRecipe_allowsAdjustments_whenSubstituteQuantityCannotBeSafelyVerified() throws {
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])
        // Milk is on hand, but measured in cups - can't be safely compared
        // to the recipe's millilitres, so PantryProof doesn't guess either
        // way; it still counts as worth trying, just unverified.
        let pantry = [PantryItem(ingredient: milk, quantity: 2, unit: .cups)]

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: LocalSubstitutionService())
            .execute(recipe: recipe, pantry: pantry)

        let evaluatedCream = evaluation.evaluatedIngredients.first
        XCTAssertEqual(evaluatedCream?.substitutions.first?.quantityAvailability, .quantityUnverified)
        XCTAssertTrue(evaluatedCream?.hasUsableSubstitution == true)
        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_evaluateRecipe_blocksCooking_whenEssentialIngredientAndItsSubstituteAreBothMissing() throws {
        let cream = makeIngredient("Cream")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .essential)
        ])

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: LocalSubstitutionService())
            .execute(recipe: recipe, pantry: [])

        XCTAssertTrue(evaluation.evaluatedIngredients.first?.substitutions.isEmpty == true)
        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_evaluateRecipe_doesNotBlockCooking_whenOptionalIngredientHasOnlyAnInsufficientSubstitute() throws {
        let chicken = makeIngredient("Chicken")
        let cream = makeIngredient("Cream")
        let milk = makeIngredient("Milk")
        let recipe = makeRecipe(ingredients: [
            RecipeIngredient(ingredient: chicken, quantity: 400, unit: .grams, role: .essential),
            RecipeIngredient(ingredient: cream, quantity: 100, unit: .milliliters, role: .optional)
        ])
        let pantry = [
            PantryItem(ingredient: chicken, quantity: 400, unit: .grams),
            PantryItem(ingredient: milk, quantity: 1, unit: .milliliters)
        ]

        let evaluation = try EvaluateRecipeFeasibilityUseCase(substitutionProvider: LocalSubstitutionService())
            .execute(recipe: recipe, pantry: pantry)

        // Optional ingredients never affect feasibility, regardless of
        // whether their substitute is sufficient, unverified, or absent.
        XCTAssertEqual(evaluation.feasibility, .readyToCook)
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
        // Rice is fine and the missing garnish is fine (it's optional),
        // but chicken (essential) missing with no substitute blocks it.
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
