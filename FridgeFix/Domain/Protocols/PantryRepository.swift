//
//  PantryRepository.swift
//  FridgeFix
//

import Foundation

/// Abstraction over where the pantry is stored.
///
/// Use cases depend on this protocol, not a concrete storage type, so
/// swapping `InMemoryPantryRepository` for something persistent later
/// wouldn't require touching any use case.
///
/// `AnyObject`-constrained because a repository is shared, mutable state -
/// every use case and view model holding one needs to see the same data.
protocol PantryRepository: AnyObject {
    /// Every item currently in the pantry.
    func fetchAll() -> [PantryItem]

    /// Adds a new item. Caller is responsible for validating it first -
    /// see `AddPantryItemUseCase`.
    func add(_ item: PantryItem)

    /// Replaces the item matching `item.id`.
    func update(_ item: PantryItem)

    /// Removes the item with the given `id`, if it exists.
    func remove(id: UUID)
}
