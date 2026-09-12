//
//  RemoveShoppingListItemUseCase.swift
//  PantryProof
//

import Foundation

/// Removes an item from the shopping list (different from
/// ``ToggleShoppingListItemUseCase``, which just marks one bought).
///
/// Same reasoning as ``RemovePantryItemUseCase`` - keeps removal on the
/// normal path and treats "item not found" as a real error.
struct RemoveShoppingListItemUseCase {
    private let shoppingListRepository: ShoppingListRepository

    init(shoppingListRepository: ShoppingListRepository) {
        self.shoppingListRepository = shoppingListRepository
    }

    @discardableResult
    func execute(id: UUID) throws -> ShoppingListItem {
        guard let item = shoppingListRepository.fetchAll().first(where: { $0.id == id }) else {
            throw RemoveShoppingListItemError.itemNotFound
        }
        shoppingListRepository.remove(id: id)
        return item
    }
}
