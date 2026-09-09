//
//  RemovePantryItemUseCase.swift
//  FridgeFix
//

import Foundation

/// Removes an item the cook has used up (or added by mistake).
///
/// Its own use case, not a direct repository call, so removal goes through
/// the same path as every other pantry mutation, and "item not found"
/// (removed elsewhere between the list rendering and the swipe landing)
/// is a real error instead of a silent no-op.
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
