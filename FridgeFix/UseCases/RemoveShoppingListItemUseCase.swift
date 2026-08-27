//
//  RemoveShoppingListItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Removes an item from the shopping list at the cook's request (as
/// opposed to ``ToggleShoppingListItemUseCase``, which marks one bought).
///
/// Kept as its own use case for the same reason as
/// ``RemovePantryItemUseCase``: it keeps shopping list removal on the same
/// `View → ViewModel → Use Case → Repository` path as every other mutation,
/// and names "item not found" as a real business condition rather than a
/// silent no-op.
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
