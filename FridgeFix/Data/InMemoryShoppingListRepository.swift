//
//  InMemoryShoppingListRepository.swift
//  FridgeFix
//

import Foundation

/// In-memory, deterministic implementation of ``ShoppingListRepository``.
///
/// Starts empty on every launch, matching FridgeFix's offline, fully
/// reproducible scope: the shopping list only ever contains what the
/// current session has added.
final class InMemoryShoppingListRepository: ShoppingListRepository {
    private var items: [ShoppingListItem]

    init(seedItems: [ShoppingListItem] = []) {
        self.items = seedItems
    }

    func fetchAll() -> [ShoppingListItem] {
        items
    }

    func add(_ item: ShoppingListItem) {
        items.append(item)
    }

    func update(_ item: ShoppingListItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }
}
