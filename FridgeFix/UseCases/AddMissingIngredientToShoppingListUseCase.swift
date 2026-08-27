//
//  AddMissingIngredientToShoppingListUseCase.swift
//  FridgeFix
//

import Foundation

/// Puts a recipe ingredient the pantry cannot cover onto the shopping list,
/// completing FridgeFix's core workflow: evaluate a recipe, see what's
/// missing, and act on it in one step from the recipe detail screen.
///
/// The quantity passed in is the recipe's own requirement — not whatever
/// partial amount the pantry might already hold — so the shopping list
/// tells the cook exactly how much to buy, not just that they need "some".
struct AddMissingIngredientToShoppingListUseCase {
    private let shoppingListRepository: ShoppingListRepository

    init(shoppingListRepository: ShoppingListRepository) {
        self.shoppingListRepository = shoppingListRepository
    }

    /// Adds `ingredient` to the shopping list at the given `quantity`/`unit`,
    /// returning the resulting item.
    @discardableResult
    func execute(ingredient: Ingredient, quantity: Double, unit: MeasurementUnit) -> ShoppingListItem {
        let item = ShoppingListItem(ingredient: ingredient, quantity: quantity, unit: unit)
        shoppingListRepository.add(item)
        return item
    }
}
