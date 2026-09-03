//
//  RemovePantryItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Removes an item the home cook has used up (or added by mistake) from
/// the pantry.
///
/// Kept as its own use case, rather than a direct repository call from the
/// view model, so pantry removal goes through the same
/// `View → ViewModel → Use Case → Repository` path as every other pantry
/// mutation, and so the "item not found" case - the item could have been
/// removed by another action between the list being displayed and the
/// swipe being handled - is a named business condition instead of a
/// silent no-op.
struct RemovePantryItemUseCase {
    private let pantryRepository: PantryRepository

    init(pantryRepository: PantryRepository) {
        self.pantryRepository = pantryRepository
    }

    @discardableResult
    func execute(id: UUID) throws -> PantryItem {
        guard let item = pantryRepository.fetchAll().first(where: { $0.id == id }) else {
            throw RemovePantryItemError.pantryItemNotFound
        }
        pantryRepository.remove(id: id)
        return item
    }
}
