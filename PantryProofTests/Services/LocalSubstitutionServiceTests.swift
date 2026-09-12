//
//  LocalSubstitutionServiceTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

/// Tests `LocalSubstitutionService` directly - specifically, that a
/// substitute's `quantityAvailability` reflects whether the pantry actually
/// has *enough* of it, not just whether it's present at all. Existing in the
/// pantry and being a usable substitute are different claims; PantryProof
/// must not collapse them into one.
final class LocalSubstitutionServiceTests: XCTestCase {
    private let service = LocalSubstitutionService()

    private func makeRecipeIngredient(_ name: String, quantity: Double, unit: MeasurementUnit) -> RecipeIngredient {
        RecipeIngredient(ingredient: Ingredient(name: name), quantity: quantity, unit: unit, role: .essential)
    }

    func test_substitutions_marksSubstituteAvailable_whenPantryQuantityClearlyCoversRequirement() {
        let cream = makeRecipeIngredient("Cream", quantity: 100, unit: .milliliters)
        let pantry = [PantryItem(ingredient: Ingredient(name: "Milk"), quantity: 500, unit: .milliliters)]

        let substitutions = service.substitutions(for: cream, availableIn: pantry)

        XCTAssertEqual(substitutions.first?.quantityAvailability, .available)
    }

    func test_substitutions_marksSubstituteInsufficient_whenPantryQuantityIsClearlyTooLittle() {
        // The exact scenario PantryProof must not get wrong: a recipe needs
        // 100 ml of Cream, Milk is a valid substitute in principle, but the
        // pantry only has 1 ml of it - nowhere near enough to actually cook
        // with. That should not read as a confidently usable substitute.
        let cream = makeRecipeIngredient("Cream", quantity: 100, unit: .milliliters)
        let pantry = [PantryItem(ingredient: Ingredient(name: "Milk"), quantity: 1, unit: .milliliters)]

        let substitutions = service.substitutions(for: cream, availableIn: pantry)

        XCTAssertEqual(substitutions.first?.quantityAvailability, .insufficient)
    }

    func test_substitutions_marksSubstituteQuantityUnverified_whenUnitsDoNotMatchRequirement() {
        // Milk is on hand, but measured in cups while the recipe needs
        // millilitres - PantryProof can't safely compare the two, so it
        // reports uncertainty rather than guessing either way.
        let cream = makeRecipeIngredient("Cream", quantity: 100, unit: .milliliters)
        let pantry = [PantryItem(ingredient: Ingredient(name: "Milk"), quantity: 2, unit: .cups)]

        let substitutions = service.substitutions(for: cream, availableIn: pantry)

        XCTAssertEqual(substitutions.first?.quantityAvailability, .quantityUnverified)
    }

    func test_substitutions_returnsNoCandidates_whenNoRuleMatchIsInThePantry() {
        let cream = makeRecipeIngredient("Cream", quantity: 100, unit: .milliliters)

        let substitutions = service.substitutions(for: cream, availableIn: [])

        XCTAssertTrue(substitutions.isEmpty)
    }

    func test_substitutions_returnsNoCandidates_whenIngredientHasNoSubstitutionRule() {
        let flour = makeRecipeIngredient("Flour", quantity: 200, unit: .grams)
        let pantry = [PantryItem(ingredient: Ingredient(name: "Milk"), quantity: 500, unit: .milliliters)]

        let substitutions = service.substitutions(for: flour, availableIn: pantry)

        XCTAssertTrue(substitutions.isEmpty)
    }
}
