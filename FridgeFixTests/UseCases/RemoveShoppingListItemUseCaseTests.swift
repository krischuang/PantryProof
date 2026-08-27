//
//  RemoveShoppingListItemUseCaseTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

final class RemoveShoppingListItemUseCaseTests: XCTestCase {
    func test_removeShoppingListItem_succeeds_whenItemExists() throws {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 1, unit: .liters)
        let repository = InMemoryShoppingListRepository(seedItems: [item])
        let useCase = RemoveShoppingListItemUseCase(shoppingListRepository: repository)

        let removed = try useCase.execute(id: item.id)

        XCTAssertEqual(removed.id, item.id)
        XCTAssertTrue(repository.fetchAll().isEmpty)
    }

    func test_removeShoppingListItem_fails_whenItemNoLongerExists() {
        let repository = InMemoryShoppingListRepository()
        let useCase = RemoveShoppingListItemUseCase(shoppingListRepository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? RemoveShoppingListItemError, .itemNotFound)
        }
    }
}
