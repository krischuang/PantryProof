//
//  ShoppingListViewModelTests.swift
//  FridgeFixTests
//

import XCTest
@testable import FridgeFix

@MainActor
final class ShoppingListViewModelTests: XCTestCase {
    func test_shoppingListViewModel_addMissingIngredient_appendsItem() {
        let viewModel = ShoppingListViewModel(shoppingListRepository: InMemoryShoppingListRepository())

        viewModel.addMissingIngredient(Ingredient(name: "Chicken", category: .meat), quantity: 400, unit: .grams)

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.name, "Chicken")
    }

    func test_shoppingListViewModel_toggleCompletion_updatesItemState() {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 1, unit: .liters, isCompleted: false)
        let viewModel = ShoppingListViewModel(shoppingListRepository: InMemoryShoppingListRepository(seedItems: [item]))

        viewModel.toggleCompletion(of: item)

        XCTAssertTrue(viewModel.items.first?.isCompleted == true)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_shoppingListViewModel_toggleCompletion_setsHumanReadableErrorMessage_whenItemNoLongerExists() {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 1, unit: .liters)
        let repository = InMemoryShoppingListRepository(seedItems: [item])
        let viewModel = ShoppingListViewModel(shoppingListRepository: repository)
        // Simulate the item having been removed elsewhere between the list
        // rendering and the cook's tap landing.
        repository.remove(id: item.id)

        viewModel.toggleCompletion(of: item)

        XCTAssertEqual(viewModel.errorMessage, ToggleShoppingListItemError.itemNotFound.errorDescription)
    }

    func test_shoppingListViewModel_removeItem_removesFromItems() {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Onion", category: .produce), quantity: 3, unit: .pieces)
        let viewModel = ShoppingListViewModel(shoppingListRepository: InMemoryShoppingListRepository(seedItems: [item]))

        viewModel.removeItem(item)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_shoppingListViewModel_removeItem_setsHumanReadableErrorMessage_whenItemNoLongerExists() {
        let item = ShoppingListItem(ingredient: Ingredient(name: "Onion", category: .produce), quantity: 3, unit: .pieces)
        let repository = InMemoryShoppingListRepository(seedItems: [item])
        let viewModel = ShoppingListViewModel(shoppingListRepository: repository)
        repository.remove(id: item.id)

        viewModel.removeItem(item)

        XCTAssertEqual(viewModel.errorMessage, RemoveShoppingListItemError.itemNotFound.errorDescription)
    }
}
