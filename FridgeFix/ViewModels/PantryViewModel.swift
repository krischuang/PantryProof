//
//  PantryViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for the Pantry screen.
///
/// `PantryViewModel` does not itself decide whether a pantry entry is
/// valid or a duplicate — it delegates that entirely to
/// ``AddPantryItemUseCase`` and maps the outcome (a refreshed items list,
/// or a typed ``AddPantryItemError``) into presentation state the view can
/// render. No pantry business rule is duplicated here.
@MainActor
@Observable
final class PantryViewModel {
    private(set) var items: [PantryItem] = []
    var errorMessage: String?

    private let pantryRepository: PantryRepository
    private let addPantryItemUseCase: AddPantryItemUseCase

    init(pantryRepository: PantryRepository = InMemoryPantryRepository()) {
        self.pantryRepository = pantryRepository
        self.addPantryItemUseCase = AddPantryItemUseCase(pantryRepository: pantryRepository)
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
        do {
            try addPantryItemUseCase.execute(name: name, quantity: quantity, unit: unit, category: category)
            loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeItem(_ item: PantryItem) {
        pantryRepository.remove(id: item.id)
        loadItems()
    }
}
