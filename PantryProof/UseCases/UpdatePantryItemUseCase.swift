//
//  UpdatePantryItemUseCase.swift
//  PantryProof
//

import Foundation

/// Updates an existing pantry item's quantity - the action
/// ``AddPantryItemError/duplicateIngredient(name:)`` points the cook to
/// when they try to re-add something they already have.
///
/// Same quantity rule as ``AddPantryItemUseCase`` (can't go negative), but
/// no duplicate check here - updating in place is the whole point. Failures
/// are reported as this use case's own ``UpdatePantryItemError``, not
/// borrowed from `AddPantryItemUseCase`.
struct UpdatePantryItemUseCase {
    private let pantryRepository: PantryRepository

    init(pantryRepository: PantryRepository) {
        self.pantryRepository = pantryRepository
    }

    @discardableResult
    func execute(id: UUID, quantity: Double, unit: MeasurementUnit) throws -> PantryItem {
        guard quantity >= 0 else {
            throw UpdatePantryItemError.invalidQuantity
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
