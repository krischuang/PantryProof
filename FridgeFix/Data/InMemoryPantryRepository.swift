//
//  InMemoryPantryRepository.swift
//  FridgeFix
//

import Foundation

/// In-memory, deterministic implementation of ``PantryRepository``.
///
/// FridgeFix runs entirely offline with no persistence across launches -
/// consistent with the app's "small, reproducible, local-only" scope,
/// where every demo run starts from the same known pantry. A future
/// implementation backed by a file or database could conform to the same
/// `PantryRepository` protocol without any use case needing to change.
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
    /// A believable starter pantry, chosen so that FridgeFix's sample
    /// recipes demonstrate every ``IngredientAvailability`` state
    /// (available, insufficient, missing) once evaluated against it.
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
