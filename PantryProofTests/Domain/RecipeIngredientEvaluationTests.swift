//
//  RecipeIngredientEvaluationTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

/// Tests `RecipeIngredientEvaluation.shoppingListQuantity` directly against
/// hand-built rows - the business rule behind "how much should Add to
/// Shopping List actually add", independent of pantry-matching (covered in
/// `EvaluateRecipeFeasibilityUseCaseTests`) and of the shopping list's own
/// duplicate/validation rules (covered in
/// `AddMissingIngredientToShoppingListUseCaseTests`).
final class RecipeIngredientEvaluationTests: XCTestCase {
    private func makeRow(
        requiredQuantity: Double,
        requiredUnit: MeasurementUnit,
        pantryQuantity: Double?,
        pantryUnit: MeasurementUnit?,
        availability: IngredientAvailability
    ) -> RecipeIngredientEvaluation {
        RecipeIngredientEvaluation(
            recipeIngredient: RecipeIngredient(
                ingredient: Ingredient(name: "Chicken"),
                quantity: requiredQuantity,
                unit: requiredUnit,
                role: .essential
            ),
            pantryQuantity: pantryQuantity,
            pantryUnit: pantryUnit,
            availability: availability,
            substitutions: []
        )
    }

    func test_shoppingListQuantity_isFullRequiredQuantity_whenIngredientIsCompletelyMissing() {
        let row = makeRow(requiredQuantity: 600, requiredUnit: .grams, pantryQuantity: nil, pantryUnit: nil, availability: .missing)

        XCTAssertEqual(row.shoppingListQuantity, 600)
    }

    func test_shoppingListQuantity_isOnlyTheShortage_whenIngredientIsInsufficient() {
        // Recipe needs 600 g, pantry already has 400 g - only the missing
        // 200 g should go on the shopping list, not the full 600 g.
        let row = makeRow(requiredQuantity: 600, requiredUnit: .grams, pantryQuantity: 400, pantryUnit: .grams, availability: .insufficient)

        XCTAssertEqual(row.shoppingListQuantity, 200)
    }

    func test_shoppingListQuantity_isNeverNegativeOrZero_whenPantryIsJustBarelyShort() {
        let row = makeRow(requiredQuantity: 600, requiredUnit: .grams, pantryQuantity: 599, pantryUnit: .grams, availability: .insufficient)

        XCTAssertEqual(row.shoppingListQuantity, 1)
        XCTAssertGreaterThan(row.shoppingListQuantity, 0)
    }

    func test_shoppingListQuantity_isZero_whenPantryExactlyMeetsRequirement() {
        // Exactly enough on hand means .available, not .insufficient - there
        // should be nothing left to add to the shopping list.
        let row = makeRow(requiredQuantity: 600, requiredUnit: .grams, pantryQuantity: 600, pantryUnit: .grams, availability: .available)

        XCTAssertEqual(row.shoppingListQuantity, 0)
    }

    func test_shoppingListQuantity_isFullRequiredQuantity_whenUnitsDifferAndCannotBeCompared() {
        // Pantry has some butter in grams, recipe measures in tablespoons -
        // PantryProof can't safely subtract across units, so it doesn't
        // guess a shortage; it asks for the full amount instead.
        let row = makeRow(requiredQuantity: 2, requiredUnit: .tablespoons, pantryQuantity: 5, pantryUnit: .grams, availability: .quantityUnverified)

        XCTAssertEqual(row.shoppingListQuantity, 2)
    }
}
