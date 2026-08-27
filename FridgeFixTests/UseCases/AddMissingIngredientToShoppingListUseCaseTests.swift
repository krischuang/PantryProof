//
//  AddMissingIngredientToShoppingListUseCaseTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

final class AddMissingIngredientToShoppingListUseCaseTests: XCTestCase {
    private func makeUseCase(seedItems: [ShoppingListItem] = []) -> (AddMissingIngredientToShoppingListUseCase, InMemoryShoppingListRepository) {
        let repository = InMemoryShoppingListRepository(seedItems: seedItems)
        return (AddMissingIngredientToShoppingListUseCase(shoppingListRepository: repository), repository)
    }

    func test_addMissingIngredient_addsNewItem_whenNotAlreadyOnList() throws {
        let (useCase, repository) = makeUseCase()
        let chicken = Ingredient(name: "Chicken", category: .meat)

        try useCase.execute(ingredient: chicken, quantity: 400, unit: .grams)

        XCTAssertEqual(repository.fetchAll().count, 1)
        XCTAssertEqual(repository.fetchAll().first?.name, "Chicken")
    }

    func test_addMissingIngredient_retainsRecipeRequiredQuantity() throws {
        let (useCase, repository) = makeUseCase()
        let rice = Ingredient(name: "Rice", category: .grain)

        try useCase.execute(ingredient: rice, quantity: 250, unit: .grams)

        XCTAssertEqual(repository.fetchAll().first?.quantity, 250)
        XCTAssertEqual(repository.fetchAll().first?.unit, .grams)
    }

    func test_addMissingIngredient_doesNotAddDuplicate_whenActiveItemAlreadyExists() throws {
        let chicken = Ingredient(name: "Chicken", category: .meat)
        let existing = ShoppingListItem(ingredient: chicken, quantity: 400, unit: .grams, isCompleted: false)
        let (useCase, repository) = makeUseCase(seedItems: [existing])

        try useCase.execute(ingredient: chicken, quantity: 400, unit: .grams)

        XCTAssertEqual(repository.fetchAll().count, 1)
    }

    func test_addMissingIngredient_addsNewItem_whenExistingItemIsAlreadyCompleted() throws {
        let chicken = Ingredient(name: "Chicken", category: .meat)
        let completed = ShoppingListItem(ingredient: chicken, quantity: 400, unit: .grams, isCompleted: true)
        let (useCase, repository) = makeUseCase(seedItems: [completed])

        try useCase.execute(ingredient: chicken, quantity: 200, unit: .grams)

        // A completed entry represents stock already bought, so a fresh
        // need for the same ingredient is a genuinely new item.
        XCTAssertEqual(repository.fetchAll().count, 2)
    }

    func test_addMissingIngredient_fails_whenRequiredQuantityIsZero() {
        let (useCase, _) = makeUseCase()
        let chicken = Ingredient(name: "Chicken", category: .meat)

        XCTAssertThrowsError(try useCase.execute(ingredient: chicken, quantity: 0, unit: .grams)) { error in
            XCTAssertEqual(error as? AddMissingIngredientToShoppingListError, .invalidRequiredQuantity)
        }
    }

    func test_addMissingIngredient_fails_whenRequiredQuantityIsNegative() {
        let (useCase, _) = makeUseCase()
        let chicken = Ingredient(name: "Chicken", category: .meat)

        XCTAssertThrowsError(try useCase.execute(ingredient: chicken, quantity: -1, unit: .grams)) { error in
            XCTAssertEqual(error as? AddMissingIngredientToShoppingListError, .invalidRequiredQuantity)
        }
    }
}
