//
//  ShoppingListViewModel.swift
//  PantryProof
//

import Foundation
import Observation

/// Presentation state and actions for the Shopping List screen.
///
/// Like ``PantryViewModel``, holds no business rules of its own - just
/// tracks the list and turns use case failures into messages the view can
/// show.
@MainActor
@Observable
final class ShoppingListViewModel {
    private(set) var items: [ShoppingListItem] = []
    var errorMessage: String?

    private let shoppingListRepository: ShoppingListRepository
    private let addMissingIngredientUseCase: AddMissingIngredientToShoppingListUseCase
    private let toggleItemUseCase: ToggleShoppingListItemUseCase
    private let removeItemUseCase: RemoveShoppingListItemUseCase

    init(shoppingListRepository: ShoppingListRepository = InMemoryShoppingListRepository()) {
        self.shoppingListRepository = shoppingListRepository
        self.addMissingIngredientUseCase = AddMissingIngredientToShoppingListUseCase(shoppingListRepository: shoppingListRepository)
        self.toggleItemUseCase = ToggleShoppingListItemUseCase(shoppingListRepository: shoppingListRepository)
        self.removeItemUseCase = RemoveShoppingListItemUseCase(shoppingListRepository: shoppingListRepository)
        loadItems()
    }

    func loadItems() {
        items = shoppingListRepository.fetchAll()
    }

    /// Adds a recipe ingredient the pantry couldn't cover, usually called
    /// from the recipe detail screen. Sets ``errorMessage`` on failure.
    func addMissingIngredient(_ ingredient: Ingredient, quantity: Double, unit: MeasurementUnit) {
        errorMessage = nil
        do {
            try addMissingIngredientUseCase.execute(ingredient: ingredient, quantity: quantity, unit: unit)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
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

    /// Removes a shopping list item. On failure (already removed
    /// elsewhere), sets ``errorMessage``.
    func removeItem(_ item: ShoppingListItem) {
        errorMessage = nil
        do {
            try removeItemUseCase.execute(id: item.id)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
