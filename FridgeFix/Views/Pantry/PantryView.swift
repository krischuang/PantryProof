//
//  PantryView.swift
//  FridgeFix
//

import SwiftUI

/// Lets the home cook see what's in their pantry, add new items, and
/// remove ones they've used up.
struct PantryView: View {
    var viewModel: PantryViewModel
    @State private var isPresentingAddItem = false
    @State private var editingItem: PantryItem?

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "Your Pantry Is Empty",
                    systemImage: "cabinet",
                    description: Text("Add ingredients you have on hand so FridgeFix can tell you which recipes are ready to cook.")
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            HStack {
                                Image(systemName: item.ingredient.category.symbolName)
                                    .foregroundStyle(.tint)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(item.ingredient.category.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(item.formattedQuantity)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.name), \(item.formattedQuantity)")
                        .accessibilityHint("Double tap to update quantity")
                    }
                    .onDelete(perform: removeItems)
                }
            }
        }
        .navigationTitle("Pantry")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddItem = true
                } label: {
                    Label("Add Ingredient", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddItem) {
            AddPantryItemView(viewModel: viewModel) { duplicateItem in
                isPresentingAddItem = false
                editingItem = duplicateItem
            }
        }
        .sheet(item: $editingItem) { item in
            UpdatePantryItemView(viewModel: viewModel, item: item)
        }
    }

    private func removeItems(at offsets: IndexSet) {
        for index in offsets {
            viewModel.removeItem(viewModel.items[index])
        }
    }
}

#Preview {
    NavigationStack {
        PantryView(viewModel: PantryViewModel())
    }
}
