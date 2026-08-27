//
//  HomeView.swift
//  FridgeFix
//

import SwiftUI

/// FridgeFix's entry point: a short summary of the pantry and shopping
/// list, and navigation into the three main workflows.
///
/// `HomeView` owns the shared repositories and view models for the whole
/// app session, so the same pantry and shopping list state is visible
/// consistently across every screen — adding an item in `PantryView` is
/// immediately reflected in a recipe evaluation, for example.
struct HomeView: View {
    @State private var pantryViewModel: PantryViewModel
    @State private var shoppingListViewModel: ShoppingListViewModel
    @State private var recipeViewModel: RecipeViewModel

    init() {
        let pantryRepository = InMemoryPantryRepository()
        let shoppingListRepository = InMemoryShoppingListRepository()
        _pantryViewModel = State(initialValue: PantryViewModel(pantryRepository: pantryRepository))
        _shoppingListViewModel = State(initialValue: ShoppingListViewModel(shoppingListRepository: shoppingListRepository))
        _recipeViewModel = State(initialValue: RecipeViewModel(pantryRepository: pantryRepository))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    LabeledContent("Pantry items", value: "\(pantryViewModel.items.count)")
                    LabeledContent("Recipes to explore", value: "\(recipeViewModel.recipes.count)")
                    LabeledContent("Shopping list", value: "\(itemsStillToBuy) to buy")
                }
                Section("FridgeFix") {
                    NavigationLink {
                        PantryView(viewModel: pantryViewModel)
                    } label: {
                        Label("Pantry", systemImage: "cabinet")
                    }
                    NavigationLink {
                        RecipeListView(recipeViewModel: recipeViewModel, shoppingListViewModel: shoppingListViewModel)
                    } label: {
                        Label("Recipes", systemImage: "fork.knife")
                    }
                    NavigationLink {
                        ShoppingListView(viewModel: shoppingListViewModel)
                    } label: {
                        Label("Shopping List", systemImage: "cart")
                    }
                }
            }
            .navigationTitle("FridgeFix")
        }
    }

    private var itemsStillToBuy: Int {
        shoppingListViewModel.items.filter { !$0.isCompleted }.count
    }
}

#Preview {
    HomeView()
}
