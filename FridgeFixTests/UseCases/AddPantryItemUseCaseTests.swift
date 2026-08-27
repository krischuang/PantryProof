//
//  AddPantryItemUseCaseTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

final class AddPantryItemUseCaseTests: XCTestCase {
    private func makeUseCase(seedItems: [PantryItem] = []) -> (AddPantryItemUseCase, InMemoryPantryRepository) {
        let repository = InMemoryPantryRepository(seedItems: seedItems)
        return (AddPantryItemUseCase(pantryRepository: repository), repository)
    }

    func test_addPantryItem_succeeds_withValidNameAndQuantity() throws {
        let (useCase, repository) = makeUseCase()

        let item = try useCase.execute(name: "Chicken", quantity: 400, unit: .grams, category: .meat)

        XCTAssertEqual(item.name, "Chicken")
        XCTAssertEqual(repository.fetchAll().count, 1)
    }

    func test_addPantryItem_succeeds_withZeroQuantity() throws {
        let (useCase, _) = makeUseCase()

        XCTAssertNoThrow(try useCase.execute(name: "Salt", quantity: 0, unit: .grams, category: .spice))
    }

    func test_addPantryItem_fails_whenIngredientNameIsEmpty() {
        let (useCase, _) = makeUseCase()

        XCTAssertThrowsError(try useCase.execute(name: "   ", quantity: 1, unit: .pieces, category: .other)) { error in
            XCTAssertEqual(error as? AddPantryItemError, .emptyIngredientName)
        }
    }

    func test_addPantryItem_fails_whenQuantityIsNegative() {
        let (useCase, _) = makeUseCase()

        XCTAssertThrowsError(try useCase.execute(name: "Flour", quantity: -1, unit: .grams, category: .grain)) { error in
            XCTAssertEqual(error as? AddPantryItemError, .invalidQuantity)
        }
    }

    func test_addPantryItem_fails_whenIngredientAlreadyExists() {
        let existing = PantryItem(ingredient: Ingredient(name: "Chicken", category: .meat), quantity: 200, unit: .grams)
        let (useCase, repository) = makeUseCase(seedItems: [existing])

        XCTAssertThrowsError(try useCase.execute(name: "Chicken", quantity: 300, unit: .grams, category: .meat)) { error in
            XCTAssertEqual(error as? AddPantryItemError, .duplicateIngredient(name: "Chicken"))
        }
        // The original entry must be untouched, not merged or duplicated.
        XCTAssertEqual(repository.fetchAll().count, 1)
        XCTAssertEqual(repository.fetchAll().first?.quantity, 200)
    }

    func test_addPantryItem_treatsNamesCaseInsensitively_asDuplicates() {
        let existing = PantryItem(ingredient: Ingredient(name: "Chicken", category: .meat), quantity: 200, unit: .grams)
        let (useCase, _) = makeUseCase(seedItems: [existing])

        XCTAssertThrowsError(try useCase.execute(name: "  chicken  ", quantity: 100, unit: .grams, category: .meat))
    }
}
