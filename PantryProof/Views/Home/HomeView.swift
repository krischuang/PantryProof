//
//  HomeView.swift
//  PantryProof
//

import SwiftUI

/// PantryProof's entry point: a quick summary plus navigation into the three
/// main screens.
///
/// Owns the shared repositories and view models for the whole session, so
/// state stays consistent everywhere - adding a pantry item shows up in
/// recipe evaluations right away.
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
                Section {
                    HStack(spacing: 10) {
                        HomeStatTile(value: "\(pantryViewModel.items.count)", label: "Pantry Items", systemImage: "cabinet.fill", tint: .green)
                        HomeStatTile(value: "\(recipeViewModel.recipes.count)", label: "Recipes", systemImage: "fork.knife", tint: .orange)
                        HomeStatTile(value: "\(itemsStillToBuy)", label: "To Buy", systemImage: "cart.fill", tint: .blue)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                } footer: {
                    Text("Track what's on hand, see what you can cook tonight, and know exactly what to buy next.")
                }

                Section("Explore") {
                    NavigationLink {
                        PantryView(viewModel: pantryViewModel)
                    } label: {
                        HomeRow(title: "Pantry", subtitle: "See what's on hand", systemImage: "cabinet.fill", tint: .green)
                    }
                    NavigationLink {
                        RecipeListView(recipeViewModel: recipeViewModel, shoppingListViewModel: shoppingListViewModel)
                    } label: {
                        HomeRow(title: "Recipes", subtitle: "Find what you can cook", systemImage: "fork.knife", tint: .orange)
                    }
                    NavigationLink {
                        ShoppingListView(viewModel: shoppingListViewModel)
                    } label: {
                        HomeRow(
                            title: "Shopping List",
                            subtitle: itemsStillToBuy == 0 ? "Nothing to buy right now" : "\(itemsStillToBuy) item\(itemsStillToBuy == 1 ? "" : "s") to buy",
                            systemImage: "cart.fill",
                            tint: .blue
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("PantryProof")
        }
    }

    private var itemsStillToBuy: Int {
        shoppingListViewModel.items.filter { !$0.isCompleted }.count
    }
}

/// One stat tile in the Home overview row - icon, number, label.
private struct HomeStatTile: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

/// A navigation row with an icon, title, and one-line subtitle - used for
/// all three Home entry points.
private struct HomeRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: systemImage, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HomeView()
}
