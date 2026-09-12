//
//  LocalSubstitutionService.swift
//  PantryProof
//

import Foundation

/// Offline implementation of ``SubstitutionProviding`` - just a fixed
/// lookup table, no network calls.
///
/// Only covers ingredients the sample recipes actually use. Not trying to
/// be a general substitution engine, just answering "is there something in
/// this pantry right now that works instead?".
struct LocalSubstitutionService: SubstitutionProviding {
    private let rulesByIngredientName: [String: [String]] = [
        "greek yogurt": ["plain yogurt", "sour cream"],
        "sour cream": ["greek yogurt", "plain yogurt"],
        "butter": ["olive oil"],
        "milk": ["oat milk", "soy milk"],
        "cream": ["milk", "cream cheese"],
        "parmesan": ["cheddar"],
    ]

    func substitutions(for recipeIngredient: RecipeIngredient, availableIn pantry: [PantryItem]) -> [PantrySubstitute] {
        guard let candidateNames = rulesByIngredientName[Self.normalized(recipeIngredient.ingredient.name)] else {
            return []
        }

        return candidateNames.compactMap { candidateName in
            guard let pantryMatch = pantry.first(where: { $0.ingredient.matches(name: candidateName) }) else {
                return nil
            }
            // The substitute has to cover the same quantity the original
            // ingredient would have - just being in the pantry isn't
            // enough to call it a real substitute.
            let quantityAvailability = IngredientAvailability.comparing(
                onHand: pantryMatch.quantity,
                unit: pantryMatch.unit,
                required: recipeIngredient.quantity,
                requiredUnit: recipeIngredient.unit
            )
            return PantrySubstitute(
                original: recipeIngredient.ingredient,
                substitute: pantryMatch.ingredient,
                quantityAvailability: quantityAvailability
            )
        }
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
