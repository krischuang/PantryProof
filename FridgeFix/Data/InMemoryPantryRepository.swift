//
//  InMemoryPantryRepository.swift
//  FridgeFix
//

import Foundation

/// In-memory implementation of ``PantryRepository``.
///
/// Nothing persists between launches - every run starts from the same
/// sample pantry. A file- or database-backed version could implement the
/// same protocol later without any use case changing.
final class InMemoryPantryRepository: PantryRepository {
    private var items: [PantryItem]

    init(seedItems: [PantryItem] = InMemoryPantryRepository.sampleItems) {
        self.items = seedItems
    }

    func fetchAll() -> [PantryItem] {
        items
    }

    func add(_ item: PantryItem) {
        items.append(item)
    }

    func update(_ item: PantryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }
}

extension InMemoryPantryRepository {
    /// A starter pantry picked so the sample recipes show off every
    /// ``IngredientAvailability`` state (available, insufficient, missing).
    static var sampleItems: [PantryItem] {
        [
            PantryItem(ingredient: Ingredient(name: "Chicken Breast", category: .meat), quantity: 400, unit: .grams),
            PantryItem(ingredient: Ingredient(name: "Rice", category: .grain), quantity: 500, unit: .grams),
            PantryItem(ingredient: Ingredient(name: "Milk", category: .dairy), quantity: 250, unit: .milliliters),
            PantryItem(ingredient: Ingredient(name: "Cheddar", category: .dairy), quantity: 150, unit: .grams),
            PantryItem(ingredient: Ingredient(name: "Eggs", category: .other), quantity: 6, unit: .pieces),
            PantryItem(ingredient: Ingredient(name: "Onion", category: .produce), quantity: 3, unit: .pieces)
        ]
    }
}
