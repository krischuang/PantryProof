//
//  ToggleShoppingListItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Marks a shopping list item as bought, or un-marks it, in response to the
/// cook checking it off during a shopping trip.
///
/// Kept as its own use case, rather than a direct repository call from the
/// view model, because the "item not found" case is a real business
/// condition worth naming — the item could have been removed by another
/// action between the list being displayed and the tap being handled — and
/// a use case is where that kind of guard belongs, not the view model.
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
