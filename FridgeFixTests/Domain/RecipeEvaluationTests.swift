//
//  RecipeEvaluationTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

/// Tests `RecipeEvaluation.feasibility` directly, against hand-built
/// evaluated ingredient rows - independent of
/// `EvaluateRecipeFeasibilityUseCase`'s pantry-matching logic (covered
/// separately in `EvaluateRecipeFeasibilityUseCaseTests`). This isolates
/// the pure business rule itself: given a set of already-evaluated rows,
/// what is the overall verdict?
final class RecipeEvaluationTests: XCTestCase {
    private func makeRow(role: IngredientRole, availability: IngredientAvailability, hasSubstitution: Bool = false) -> RecipeIngredientEvaluation {
        let ingredient = Ingredient(name: "Test Ingredient")
        let substitutions = hasSubstitution
            ? [IngredientSubstitution(original: ingredient, substitute: Ingredient(name: "Substitute"))]
            : []
        return RecipeIngredientEvaluation(
            recipeIngredient: RecipeIngredient(ingredient: ingredient, quantity: 1, unit: .pieces, role: role),
            pantryQuantity: availability == .missing ? nil : 0,
            pantryUnit: availability == .missing ? nil : .pieces,
            availability: availability,
            substitutions: substitutions
        )
    }

    private func makeEvaluation(_ rows: [RecipeIngredientEvaluation]) -> RecipeEvaluation {
        RecipeEvaluation(
            recipe: Recipe(name: "Test Recipe", summary: "", ingredients: rows.map(\.recipeIngredient)),
            evaluatedIngredients: rows
        )
    }

    func test_feasibility_isReadyToCook_whenEveryIngredientIsAvailable() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .available),
            makeRow(role: .replaceable, availability: .available),
            makeRow(role: .optional, availability: .available)
        ])

        XCTAssertEqual(evaluation.feasibility, .readyToCook)
    }

    func test_feasibility_isBlocked_whenEssentialIngredientHasNoSubstitution() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .missing, hasSubstitution: false)
        ])

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_feasibility_isBlocked_whenReplaceableIngredientHasNoSubstitution() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .available),
            makeRow(role: .replaceable, availability: .insufficient, hasSubstitution: false)
        ])

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }

    func test_feasibility_isCanMakeWithAdjustments_whenUnresolvedIngredientHasSubstitution() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .available),
            makeRow(role: .replaceable, availability: .missing, hasSubstitution: true)
        ])

        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_feasibility_ignoresOptionalIngredients_regardlessOfAvailabilityOrSubstitution() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .available),
            makeRow(role: .replaceable, availability: .available),
            makeRow(role: .optional, availability: .missing, hasSubstitution: false)
        ])

        XCTAssertEqual(evaluation.feasibility, .readyToCook)
    }

    func test_feasibility_isCanMakeWithAdjustments_whenEssentialIngredientQuantityIsUnverified() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .quantityUnverified, hasSubstitution: false)
        ])

        // Presence is confirmed but the amount is not - never blocked, but
        // never a bare "ready to cook" either.
        XCTAssertEqual(evaluation.feasibility, .canMakeWithAdjustments)
    }

    func test_feasibility_ignoresOptionalIngredients_whenQuantityIsUnverified() {
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .available),
            makeRow(role: .optional, availability: .quantityUnverified, hasSubstitution: false)
        ])

        XCTAssertEqual(evaluation.feasibility, .readyToCook)
    }

    func test_feasibility_prefersBlocked_whenBothUnresolvedAndAdjustableIngredientsExist() {
        // A blocked essential ingredient must dominate the verdict even
        // when another ingredient could be adjusted for - FridgeFix never
        // reports "can make with adjustments" while something remains
        // genuinely blocking.
        let evaluation = makeEvaluation([
            makeRow(role: .essential, availability: .missing, hasSubstitution: false),
            makeRow(role: .replaceable, availability: .missing, hasSubstitution: true)
        ])

        XCTAssertEqual(evaluation.feasibility, .blocked)
    }
}
