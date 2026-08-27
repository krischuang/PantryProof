//
//  UpdatePantryItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Updates the quantity of an existing pantry item — the action FridgeFix
/// actually points the cook toward when ``AddPantryItemError/duplicateIngredient(name:)``
/// tells them to "update its quantity instead of adding it again".
///
/// Without this use case, that error message would be advice the app
/// itself couldn't follow through on. It applies the same quantity rule as
/// ``AddPantryItemUseCase`` — quantity must be zero or greater — but does
/// not repeat the duplicate check, since updating an item's quantity in
/// place is exactly the action that check is meant to encourage.
struct UpdatePantryItemUseCase {
    private let pantryRepository: PantryRepository

    init(pantryRepository: PantryRepository) {
        self.pantryRepository = pantryRepository
    }

    @discardableResult
    func execute(id: UUID, quantity: Double, unit: MeasurementUnit) throws -> PantryItem {
        guard quantity >= 0 else {
            throw AddPantryItemError.invalidQuantity
        }
        guard var item = pantryRepository.fetchAll().first(where: { $0.id == id }) else {
            throw UpdatePantryItemError.itemNotFound
        }
        item.quantity = quantity
        item.unit = unit
        pantryRepository.update(item)
        return item
    }
}
