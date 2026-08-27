//
//  PantryRepository.swift
//  FridgeFix
//

import Foundation

/// Abstraction over where the home cook's pantry is stored.
///
/// Use cases depend on this protocol, not on any concrete storage
/// mechanism, so `AddPantryItemUseCase` (and future pantry use cases) stay
/// unaware of whether the pantry lives in memory, in a file, or in a
/// database. FridgeFix's current scope only needs a deterministic,
/// in-memory implementation (`InMemoryPantryRepository`), but nothing
/// above this protocol needs to change if that later becomes persistent.
protocol PantryRepository {
    /// Every item currently in the pantry.
    func fetchAll() -> [PantryItem]

    /// Adds a new item to the pantry. Callers are responsible for having
    /// already validated the item — see `AddPantryItemUseCase`.
    func add(_ item: PantryItem)

    /// Replaces an existing pantry item (matched by `id`) with `item`.
    func update(_ item: PantryItem)

    /// Removes the pantry item with the given `id`, if one exists.
    func remove(id: UUID)
}
