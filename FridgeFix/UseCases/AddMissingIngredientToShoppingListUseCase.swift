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
    ///
    /// **Duplicate rule:** if the ingredient is already on the list and not
    /// yet ``ShoppingListItem/isCompleted``, that existing entry is
    /// returned unchanged instead of adding a second row — tapping "Add to
    /// Shopping List" from a recipe the cook has already flagged should not
    /// create a growing pile of duplicate entries for the same trip. Once
    /// an entry is marked completed (bought), it no longer counts as a
    /// duplicate: the cook has used up that stock and a fresh need for the
    /// same ingredient is a genuinely new item to buy.
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
