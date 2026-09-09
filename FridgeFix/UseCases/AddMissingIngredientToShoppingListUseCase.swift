//
//  AddMissingIngredientToShoppingListUseCase.swift
//  FridgeFix
//

import Foundation

/// Adds a recipe ingredient the pantry can't cover to the shopping list.
///
/// Uses the recipe's required quantity, not whatever partial amount the
/// pantry already has, so the list says exactly how much to buy.
struct AddMissingIngredientToShoppingListUseCase {
    private let shoppingListRepository: ShoppingListRepository

    init(shoppingListRepository: ShoppingListRepository) {
        self.shoppingListRepository = shoppingListRepository
    }

    /// Adds `ingredient` to the shopping list, returning the resulting item.
    ///
    /// **Duplicate rule:** if it's already on the list and not yet bought,
    /// return that entry instead of adding a second one - tapping "Add"
    /// twice shouldn't create duplicates. Once an item is bought, it
    /// doesn't count anymore, since a fresh need is a genuinely new item.
    ///
    /// - Throws: ``AddMissingIngredientToShoppingListError/invalidRequiredQuantity``
    ///   if `quantity` is zero or negative.
    @discardableResult
    func execute(ingredient: Ingredient, quantity: Double, unit: MeasurementUnit) throws -> ShoppingListItem {
        guard quantity > 0 else {
            throw AddMissingIngredientToShoppingListError.invalidRequiredQuantity
        }
        if let activeItem = shoppingListRepository.fetchAll().first(where: {
            !$0.isCompleted && $0.ingredient.matches(ingredient)
        }) {
            return activeItem
        }

        let item = ShoppingListItem(ingredient: ingredient, quantity: quantity, unit: unit)
        shoppingListRepository.add(item)
        return item
    }
}
