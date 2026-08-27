//
//  ShoppingListViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for the Shopping List screen.
///
/// Like ``PantryViewModel``, this type holds no shopping-list business
/// rules itself — duplicate prevention lives in
/// ``AddMissingIngredientToShoppingListUseCase`` and the "item not found"
/// guard lives in ``ToggleShoppingListItemUseCase``. The view model only
/// tracks the current list and maps use case failures into a message the
/// view can show.
@MainActor
@Observable
final class ShoppingListViewModel {
    private(set) var items: [ShoppingListItem] = []
    var errorMessage: String?

    private let shoppingListRepository: ShoppingListRepository
    private let addMissingIngredientUseCase: AddMissingIngredientToShoppingListUseCase
    private let toggleItemUseCase: ToggleShoppingListItemUseCase

    init(shoppingListRepository: ShoppingListRepository = InMemoryShoppingListRepository()) {
        self.shoppingListRepository = shoppingListRepository
        self.addMissingIngredientUseCase = AddMissingIngredientToShoppingListUseCase(shoppingListRepository: shoppingListRepository)
        self.toggleItemUseCase = ToggleShoppingListItemUseCase(shoppingListRepository: shoppingListRepository)
        loadItems()
    }

    func loadItems() {
        items = shoppingListRepository.fetchAll()
    }

    /// Adds a recipe ingredient the pantry couldn't cover, typically called
    /// from the recipe detail screen.
    func addMissingIngredient(_ ingredient: Ingredient, quantity: Double, unit: MeasurementUnit) {
        addMissingIngredientUseCase.execute(ingredient: ingredient, quantity: quantity, unit: unit)
        loadItems()
    }

    func toggleCompletion(of item: ShoppingListItem) {
        errorMessage = nil
        do {
            try toggleItemUseCase.execute(id: item.id)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(_ item: ShoppingListItem) {
        shoppingListRepository.remove(id: item.id)
        loadItems()
    }
}
