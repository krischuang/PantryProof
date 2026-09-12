//
//  InMemoryRecipeRepository.swift
//  PantryProof
//

import Foundation

/// Offline implementation of ``RecipeRepository``.
///
/// The four sample recipes aren't random - together they hit every
/// ``RecipeFeasibility`` outcome against
/// ``InMemoryPantryRepository/sampleItems``, so the app demos its full
/// behaviour without any manual setup.
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
            // Everything essential/replaceable is available - only the
            // optional ingredient is missing, so it doesn't block cooking.
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
            // Chicken (essential) is short and Pasta (essential) is
            // missing, neither has a substitute - blocked, even though
            // Cream has one (Milk).
            Recipe(
                name: "Creamy Chicken Pasta",
                summary: "A rich stovetop pasta with a simple cream sauce.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Chicken Breast", category: .meat), quantity: 600, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Pasta", category: .grain), quantity: 200, unit: .grams, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Cream", category: .dairy), quantity: 100, unit: .milliliters, role: .replaceable)
                ]
            ),
            // Eggs (essential) are available; Parmesan (replaceable) is
            // missing but Cheddar covers it - can make with adjustments.
            Recipe(
                name: "Parmesan Baked Eggs",
                summary: "Baked eggs with a golden, cheesy crust.",
                ingredients: [
                    RecipeIngredient(ingredient: Ingredient(name: "Eggs", category: .other), quantity: 3, unit: .pieces, role: .essential),
                    RecipeIngredient(ingredient: Ingredient(name: "Parmesan", category: .dairy), quantity: 50, unit: .grams, role: .replaceable),
                    RecipeIngredient(ingredient: Ingredient(name: "Chives", category: .produce), quantity: 1, unit: .tablespoons, role: .optional)
                ]
            ),
            // Rice (essential) is available; Butter (replaceable) is
            // missing with no substitute (no Olive Oil in the pantry) -
            // blocked, even though Garlic is only optional.
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
