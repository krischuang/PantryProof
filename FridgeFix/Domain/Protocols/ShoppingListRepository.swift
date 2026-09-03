//
//  ShoppingListRepository.swift
//  FridgeFix
//

import Foundation

/// Abstraction over where the home cook's shopping list is stored.
///
/// Mirrors ``PantryRepository``: use cases depend on this protocol, not on
/// any concrete storage mechanism, so a future persistent implementation
/// could replace `InMemoryShoppingListRepository` without any use case
/// needing to change.
protocol ShoppingListRepository: AnyObject {
    /// Every item currently on the shopping list.
    func fetchAll() -> [ShoppingListItem]

    /// Adds a new item to the shopping list.
    func add(_ item: ShoppingListItem)

    /// Replaces an existing shopping list item (matched by `id`) with
    /// `item` - used to persist a completion toggle or quantity change.
    func update(_ item: ShoppingListItem)

    /// Removes the shopping list item with the given `id`, if one exists.
    func remove(id: UUID)
}
