//
//  InMemoryRecipeRepository.swift
//  FridgeFix
//

import Foundation

/// Deterministic, offline implementation of ``RecipeRepository``.
///
/// The four sample recipes are chosen deliberately, not arbitrarily, to
/// demonstrate every ``RecipeFeasibility`` outcome against
/// ``InMemoryPantryRepository/sampleItems`` - including the two different
/// ways a recipe can end up ``RecipeFeasibility/blocked`` (an insufficient
/// essential ingredient, and a missing replaceable ingredient with no
/// substitute) so the app never has to be edited by hand to show the full
/// range of behaviour.
final class InMemoryRecipeRepository: RecipeRepository {
    private let recipes: [Recipe]

    init(recipes: [Recipe] = InMemoryRecipeRepository.sampleRecipes) {
        self.recipes = recipes
    }

    func fetchAll() -> [Recipe] {
        recipes
    }
}

extension InMemoryRecipeRepository {
    static var sampleRecipes: [Recipe] {
        [
            // All essential/replaceable ingredients fully available; an
            // optional ingredient is missing but does not block cooking.
            Recipe(
                name: "Chicken Fried Rice",
                summary: "A quick weeknight stir-fry using pantry staples.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Chicken Breast", category: .meat), quantity: 400, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Rice", category: .grain), quantity: 300, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Eggs", category: .other), quantity: 2, unit: .pieces, role: .replaceable),
                    RecipeIngredient(ingredient: Ingredient(name: "Onion", category: .produce), quantity: 1, unit: .pieces, role: .replaceable),
                    RecipeIngredient(ingredient: Ingredient(name: "Spring Onion", category: .produce), quantity: 1, unit: .tablespoons, role: .optional)
                ]
            ),
            // Essential Chicken Breast is insufficient (pantry has 400g,
            // needs 600g) and essential Pasta is missing entirely - neither
            // has a substitute, so the recipe is blocked even though Cream
            // (replaceable) has a usable substitute in Milk.
            Recipe(
                name: "Creamy Chicken Pasta",
                summary: "A rich stovetop pasta with a simple cream sauce.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Chicken Breast", category: .meat), quantity: 600, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Pasta", category: .grain), quantity: 200, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Cream", category: .dairy), quantity: 100, unit: .milliliters, role: .replaceable)
                ]
            ),
            // Essential Eggs are available; replaceable Parmesan is missing
            // but has a usable substitute (Cheddar, already in the
            // pantry), so the recipe can be made with adjustments.
            Recipe(
                name: "Parmesan Baked Eggs",
                summary: "Baked eggs with a golden, cheesy crust.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Eggs", category: .other), quantity: 3, unit: .pieces, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Parmesan", category: .dairy), quantity: 50, unit: .grams, role: .replaceable),
                    RecipeIngredient(ingredient: Ingredient(name: "Chives", category: .produce), quantity: 1, unit: .tablespoons, role: .optional)
                ]
            ),
            // Essential Rice is available; replaceable Butter is missing
            // with no usable substitute (Olive Oil is not in the pantry),
            // so the recipe is blocked - even though the only other
            // missing ingredient (Garlic) is merely optional.
            Recipe(
                name: "Garlic Butter Rice",
                summary: "Simple buttery rice with garlic.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Rice", category: .grain), quantity: 200, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Butter", category: .dairy), quantity: 2, unit: .tablespoons, role: .replaceable),
                    RecipeIngredient(ingredient: Ingredient(name: "Garlic", category: .produce), quantity: 1, unit: .pieces, role: .optional)
                ]
            )
        ]
    }
}
