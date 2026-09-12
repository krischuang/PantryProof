//
//  ShoppingListRepository.swift
//  PantryProof
//

import Foundation

/// Abstraction over where the shopping list is stored.
///
/// Same idea as ``PantryRepository`` - use cases depend on this protocol
/// so storage can change later without touching them.
protocol ShoppingListRepository: AnyObject {
    /// Every item currently on the shopping list.
    func fetchAll() -> [ShoppingListItem]

    /// Adds a new item.
    func add(_ item: ShoppingListItem)

    /// Replaces the item matching `item.id` - used for toggling completion
    /// or changing quantity.
    func update(_ item: ShoppingListItem)

    /// Removes the item with the given `id`, if it exists.
    func remove(id: UUID)
}
