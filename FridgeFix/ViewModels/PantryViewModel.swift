//
//  PantryViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for the Pantry screen.
///
/// `PantryViewModel` does not itself decide whether a pantry entry is
/// valid or a duplicate - it delegates that entirely to
/// ``AddPantryItemUseCase`` / ``UpdatePantryItemUseCase`` and maps the
/// outcome (a refreshed items list, or a typed error) into presentation
/// state the view can render. No pantry business rule is duplicated here.
@MainActor
@Observable
final class PantryViewModel {
    private(set) var items: [PantryItem] = []
    var errorMessage: String?
    /// Set when ``addItem(name:quantity:unit:category:)`` fails because the
    /// ingredient already exists, so the view can offer "update the
    /// existing item" as a concrete next action instead of leaving the
    /// cook to hunt for it themselves.
    private(set) var duplicateItem: PantryItem?
    /// Set when ``removeItem(_:)`` fails. Kept separate from
    /// ``errorMessage`` so a removal failure (surfaced as its own alert)
    /// can never be confused with an add/update form's inline error.
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

    /// Attempts to add a pantry item. On failure, ``errorMessage`` is set
    /// to the failure's human-readable description; the view is
    /// responsible for presenting it.
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

    /// Attempts to update an existing pantry item's quantity/unit. On
    /// failure, ``errorMessage`` is set to the failure's human-readable
    /// description.
    func updateQuantity(for item: PantryItem, quantity: Double, unit: MeasurementUnit) {
        errorMessage = nil
        do {
            try updatePantryItemUseCase.execute(id: item.id, quantity: quantity, unit: unit)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Attempts to remove a pantry item. On failure (the item was already
    /// removed by another action), ``removalErrorMessage`` is set to the
    /// failure's human-readable description.
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
