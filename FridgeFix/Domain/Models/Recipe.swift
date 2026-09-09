//
//  Recipe.swift
//  FridgeFix
//

import Foundation

/// A dish the cook might want to make: a name, a summary, and the
/// ingredients it needs.
///
/// Recipe itself stays simple - quantities, units, and role all live on
/// ``RecipeIngredient`` so evaluation logic doesn't creep in here.
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
