//
//  LocalSubstitutionService.swift
//  FridgeFix
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

    func substitutions(for ingredient: Ingredient, availableIn pantry: [PantryItem]) -> [PantrySubstitute] {
        guard let candidateNames = rulesByIngredientName[Self.normalized(ingredient.name)] else {
            return []
        }

        return candidateNames.compactMap { candidateName in
            guard let pantryMatch = pantry.first(where: { $0.ingredient.matches(name: candidateName) }) else {
                return nil
            }
            return PantrySubstitute(original: ingredient, substitute: pantryMatch.ingredient)
        }
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
