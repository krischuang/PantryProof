//
//  ToggleShoppingListItemUseCaseTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

final class ToggleShoppingListItemUseCaseTests: XCTestCase {
    func test_toggleItem_marksIncompleteItemAsCompleted() throws {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 1, unit: .liters, isCompleted: false)
        let repository = InMemoryShoppingListRepository(seedItems: [item])
        let useCase = ToggleShoppingListItemUseCase(shoppingListRepository: repository)

        let toggled = try useCase.execute(id: item.id)

        XCTAssertTrue(toggled.isCompleted)
        XCTAssertTrue(repository.fetchAll().first?.isCompleted == true)
    }

    func test_toggleItem_marksCompletedItemAsIncomplete() throws {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 1, unit: .liters, isCompleted: true)
        let repository = InMemoryShoppingListRepository(seedItems: [item])
        let useCase = ToggleShoppingListItemUseCase(shoppingListRepository: repository)

        let toggled = try useCase.execute(id: item.id)

        XCTAssertFalse(toggled.isCompleted)
    }

    func test_toggleItem_fails_whenItemNotFound() {
        let repository = InMemoryShoppingListRepository()
        let useCase = ToggleShoppingListItemUseCase(shoppingListRepository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertEqual(error as? ToggleShoppingListItemError, .itemNotFound)
        }
    }
}
