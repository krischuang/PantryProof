//
//  AddPantryItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Adds a new item to the home cook's pantry, enforcing the validation
/// rules that keep the pantry - and therefore every recipe evaluation
/// built on top of it - trustworthy.
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
    /// **Duplicate rule:** if an ingredient with the same name (matched via
    /// ``Ingredient/matches(name:)``) is already in the pantry, the new
    /// entry is rejected rather than merged or added as a second row.
    /// Silently merging quantities would hide a data-entry mistake (was
    /// the cook re-adding chicken because they forgot they already had
    /// some, or because they bought more?), and a second row for the same
    /// ingredient would make every future pantry lookup and recipe
    /// evaluation ambiguous about which row is authoritative. Asking the
    /// cook to update the existing entry keeps the pantry's "one row per
    /// ingredient" invariant intact.
    ///
    /// - Throws: ``AddPantryItemError/emptyIngredientName`` if `name` is
    ///   blank, ``AddPantryItemError/invalidQuantity`` if `quantity` is
    ///   negative, or ``AddPantryItemError/duplicateIngredient(name:)`` if
    ///   the ingredient is already in the pantry.
    @discardableResult
    func execute(name: String, quantity: Double, unit: MeasurementUnit, category: IngredientCategory) throws -> PantryItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AddPantryItemError.emptyIngredientName
        }
        guard quantity >= 0 else {
            throw AddPantryItemError.invalidQuantity
        }
        if let existing = pantryRepository.fetchAll().first(where: { $0.ingredient.matches(name: trimmedName) }) {
            throw AddPantryItemError.duplicateIngredient(name: existing.name)
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
