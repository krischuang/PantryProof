//
//  Recipe.swift
//  FridgeFix
//

import Foundation

/// A dish the home cook might want to make, expressed as a name, a short
/// summary, and the list of ingredients it requires.
///
/// `Recipe` is the starting point of FridgeFix's core workflow: the cook
/// browses recipes, picks one, and asks "can I still make this?". Everything
/// needed to answer that question — quantities, units, and each
/// ingredient's ``IngredientRole`` — lives on its ``RecipeIngredient``
/// entries, keeping `Recipe` itself a simple composition root rather than a
/// place where evaluation logic could creep in.
struct Recipe: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var summary: String
    var ingredients: [RecipeIngredient]

    init(id: UUID = UUID(), name: String, summary: String, ingredients: [RecipeIngredient]) {
        self.id = id
        self.name = name
        self.summary = summary
        self.ingredients = ingredients
    }
}
