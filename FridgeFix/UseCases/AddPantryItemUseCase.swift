//
//  AddPantryItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Adds a new item to the home cook's pantry, enforcing the validation
/// rules that keep the pantry — and therefore every recipe evaluation
/// built on top of it — trustworthy.
///
/// An invalid or duplicated pantry entry does not just look wrong in the
/// list; it silently corrupts every future ``EvaluateRecipeFeasibilityUseCase``
/// result computed against that pantry. Centralising validation here,
/// rather than in the view or view model, means there is exactly one place
/// that can produce a pantry item, and it cannot be bypassed.
struct AddPantryItemUseCase {
    private let pantryRepository: PantryRepository

    init(pantryRepository: PantryRepository) {
        self.pantryRepository = pantryRepository
    }

    /// Validates and adds a pantry item, returning the item that was
    /// stored.
    ///
    /// - Throws: ``AddPantryItemError/emptyIngredientName`` if `name` is
    ///   blank, or ``AddPantryItemError/invalidQuantity`` if `quantity` is
    ///   negative.
    @discardableResult
    func execute(name: String, quantity: Double, unit: MeasurementUnit, category: IngredientCategory) throws -> PantryItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AddPantryItemError.emptyIngredientName
        }
        guard quantity >= 0 else {
            throw AddPantryItemError.invalidQuantity
        }

        let item = PantryItem(
            ingredient: Ingredient(name: trimmedName, category: category),
            quantity: quantity,
            unit: unit
        )
        pantryRepository.add(item)
        return item
    }
}
