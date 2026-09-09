//
//  RecipeListView.swift
//  FridgeFix
//

import SwiftUI

/// Lets the home cook browse FridgeFix's recipes and jump into the detail
/// screen to ask "can I still make this?" about any of them.
struct RecipeListView: View {
    var recipeViewModel: RecipeViewModel
    var shoppingListViewModel: ShoppingListViewModel

    var body: some View {
        List(recipeViewModel.recipes) { recipe in
            NavigationLink {
                RecipeDetailView(
                    recipe: recipe,
                    recipeViewModel: recipeViewModel,
                    shoppingListViewModel: shoppingListViewModel
                )
            } label: {
                RecipeRow(recipe: recipe, feasibility: recipeViewModel.feasibility(for: recipe))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Recipes")
        .onAppear {
            recipeViewModel.loadRecipes()
        }
    }
}

private struct RecipeRow: View {
    let recipe: Recipe
    let feasibility: RecipeFeasibility

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Label("\(recipe.ingredients.count) ingredient\(recipe.ingredients.count == 1 ? "" : "s")", systemImage: "list.bullet")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
            Image(systemName: feasibility.symbolName)
                .font(.title3)
                .foregroundStyle(feasibility.color)
                .frame(width: 32, height: 32)
                .background(feasibility.color.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name). \(feasibility.title).")
    }
}

#Preview {
    let pantryRepository = InMemoryPantryRepository()
    NavigationStack {
        RecipeListView(
            recipeViewModel: RecipeViewModel(pantryRepository: pantryRepository),
            shoppingListViewModel: ShoppingListViewModel()
        )
    }
}
