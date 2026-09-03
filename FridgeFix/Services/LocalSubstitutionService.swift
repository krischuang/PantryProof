//
//  LocalSubstitutionService.swift
//  FridgeFix
//

import Foundation

/// Deterministic, fully offline implementation of ``SubstitutionProviding``.
///
/// FridgeFix runs from local data only - no network calls, no AI-generated
/// suggestions - so the same recipe and pantry always produce the same
/// substitution guidance. Rules are a small, fixed table of ingredient
/// name → candidate names, covering the ingredients FridgeFix's sample
/// recipes actually use. This is intentionally not a general-purpose
/// recommendation engine: FridgeFix only needs to answer "is there
/// something in this cook's pantry, right now, that could stand in for
/// this ingredient?", not "what could stand in for this ingredient in
/// general?".
struct LocalSubstitutionService: SubstitutionProviding {
    private let rulesByIngredientName: [String: [String]] = [
        "greek yogurt": ["plain yogurt", "sour cream"],
        "sour cream": ["greek yogurt", "plain yogurt"],
        "butter": ["olive oil"],
        "milk": ["oat milk", "soy milk"],
        "cream": ["milk", "cream cheese"],
        "parmesan": ["cheddar"],
    ]

    func substitutions(for ingredient: Ingredient, availableIn pantry: [PantryItem]) -> [IngredientSubstitution] {
        guard let candidateNames = rulesByIngredientName[Self.normalized(ingredient.name)] else {
            return []
        }

        return candidateNames.compactMap { candidateName in
            guard let pantryMatch = pantry.first(where: { $0.ingredient.matches(name: candidateName) }) else {
                return nil
            }
            return IngredientSubstitution(original: ingredient, substitute: pantryMatch.ingredient)
        }
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
