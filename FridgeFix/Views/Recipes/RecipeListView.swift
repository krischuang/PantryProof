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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Label(feasibility.title, systemImage: feasibility.symbolName)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(color(for: feasibility))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.name). \(feasibility.title).")
    }

    private func color(for feasibility: RecipeFeasibility) -> Color {
        switch feasibility {
        case .readyToCook: return .green
        case .canMakeWithAdjustments: return .orange
        case .blocked: return .red
        }
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
