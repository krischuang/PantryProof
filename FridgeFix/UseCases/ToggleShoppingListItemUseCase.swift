//
//  ToggleShoppingListItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Marks a shopping list item bought, or un-marks it, when the cook taps it.
///
/// Its own use case so "item not found" (removed elsewhere between the
/// list rendering and the tap landing) is a real error, not something the
/// view model has to guard against itself.
struct ToggleShoppingListItemUseCase {
    private let shoppingListRepository: ShoppingListRepository

    init(shoppingListRepository: ShoppingListRepository) {
        self.shoppingListRepository = shoppingListRepository
    }

    @discardableResult
    func execute(id: UUID) throws -> ShoppingListItem {
        guard var item = shoppingListRepository.fetchAll().first(where: { $0.id == id }) else {
            throw ToggleShoppingListItemError.itemNotFound
        }
        item.isCompleted.toggle()
        shoppingListRepository.update(item)
        return item
    }
}
