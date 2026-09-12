//
//  RemovePantryItemUseCaseTests.swift
//  PantryProofTests
//

import XCTest
@testable import PantryProof

final class RemovePantryItemUseCaseTests: XCTestCase {
    func test_removePantryItem_succeeds_whenItemExists() throws {
        let item = PantryItem(ingredient: Ingredient(name: "Onion", category: .produce), quantity: 3, unit: .pieces)
        let repository = InMemoryPantryRepository(seedItems: [item])
        let useCase = RemovePantryItemUseCase(pantryRepository: repository)

        let removed = try useCase.execute(id: item.id)

        XCTAssertEqual(removed.id, item.id)
        XCTAssertTrue(repository.fetchAll().isEmpty)
    }

    func test_removePantryItem_fails_whenItemNoLongerExists() {
        let repository = InMemoryPantryRepository(seedItems: [])
        let useCase = RemovePantryItemUseCase(pantryRepository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? RemovePantryItemError, .pantryItemNotFound)
        }
    }
}
