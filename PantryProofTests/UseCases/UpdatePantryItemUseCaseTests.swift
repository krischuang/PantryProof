//
//  UpdatePantryItemUseCaseTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

final class UpdatePantryItemUseCaseTests: XCTestCase {
    func test_updatePantryItem_succeeds_withValidQuantity() throws {
        let item = PantryItem(ingredient: Ingredient(name: "Chicken", category: .meat), quantity: 200, unit: .grams)
        let repository = InMemoryPantryRepository(seedItems: [item])
        let useCase = UpdatePantryItemUseCase(pantryRepository: repository)

        let updated = try useCase.execute(id: item.id, quantity: 500, unit: .grams)

        XCTAssertEqual(updated.quantity, 500)
        XCTAssertEqual(repository.fetchAll().first?.quantity, 500)
    }

    func test_updatePantryItem_fails_whenQuantityIsNegative() {
        let item = PantryItem(ingredient: Ingredient(name: "Chicken", category: .meat), quantity: 200, unit: .grams)
        let repository = InMemoryPantryRepository(seedItems: [item])
        let useCase = UpdatePantryItemUseCase(pantryRepository: repository)

        XCTAssertThrowsError(try useCase.execute(id: item.id, quantity: -1, unit: .grams)) { error in
            XCTAssertEqual(error as? AddPantryItemError, .invalidQuantity)
        }
    }

    func test_updatePantryItem_fails_whenItemNoLongerExists() {
        let repository = InMemoryPantryRepository(seedItems: [])
        let useCase = UpdatePantryItemUseCase(pantryRepository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID(), quantity: 100, unit: .grams)) { error in
            XCTAssertEqual(error as? UpdatePantryItemError, .itemNotFound)
        }
    }
}
