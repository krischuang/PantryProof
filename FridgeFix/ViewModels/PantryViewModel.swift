//
//  PantryViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for the Pantry screen.
///
/// Doesn't decide validity or duplicates itself - that's all delegated to
/// ``AddPantryItemUseCase`` / ``UpdatePantryItemUseCase``. This just maps
/// the result into something the view can render.
@MainActor
@Observable
final class PantryViewModel {
    private(set) var items: [PantryItem] = []
    var errorMessage: String?
    /// Set when adding fails because the ingredient's a duplicate, so the
    /// view can offer "update the existing item" instead.
    private(set) var duplicateItem: PantryItem?
    /// Set when removal fails. Separate from `errorMessage` so a removal
    /// alert never gets mixed up with a form's inline error.
    var removalErrorMessage: String?

    private let pantryRepository: PantryRepository
    private let addPantryItemUseCase: AddPantryItemUseCase
    private let updatePantryItemUseCase: UpdatePantryItemUseCase
    private let removePantryItemUseCase: RemovePantryItemUseCase

    init(pantryRepository: PantryRepository = InMemoryPantryRepository()) {
        self.pantryRepository = pantryRepository
        self.addPantryItemUseCase = AddPantryItemUseCase(pantryRepository: pantryRepository)
        self.updatePantryItemUseCase = UpdatePantryItemUseCase(pantryRepository: pantryRepository)
        self.removePantryItemUseCase = RemovePantryItemUseCase(pantryRepository: pantryRepository)
        loadItems()
    }

    func loadItems() {
        items = pantryRepository.fetchAll()
    }

    /// Adds a pantry item. On failure, sets ``errorMessage`` for the view
    /// to display.
    func addItem(name: String, quantity: Double, unit: MeasurementUnit, category: IngredientCategory) {
        errorMessage = nil
        duplicateItem = nil
        do {
            try addPantryItemUseCase.execute(name: name, quantity: quantity, unit: unit, category: category)
            loadItems()
        } catch let error as AddPantryItemError {
            errorMessage = error.errorDescription
            if case .duplicateIngredient(let existingName) = error {
                duplicateItem = items.first { $0.name.caseInsensitiveCompare(existingName) == .orderedSame }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates a pantry item's quantity/unit. On failure, sets
    /// ``errorMessage``.
    func updateQuantity(for item: PantryItem, quantity: Double, unit: MeasurementUnit) {
        errorMessage = nil
        do {
            try updatePantryItemUseCase.execute(id: item.id, quantity: quantity, unit: unit)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Removes a pantry item. On failure (already removed elsewhere), sets
    /// ``removalErrorMessage``.
    func removeItem(_ item: PantryItem) {
        removalErrorMessage = nil
        do {
            try removePantryItemUseCase.execute(id: item.id)
            loadItems()
        } catch {
            removalErrorMessage = error.localizedDescription
        }
    }
}
