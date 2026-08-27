//
//  ShoppingListView.swift
//  FridgeFix
//

import SwiftUI

/// Shows what the home cook still needs to buy, with items added directly
/// from recipe evaluations already pre-filled with the required quantity.
struct ShoppingListView: View {
    var viewModel: ShoppingListViewModel

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "Your Shopping List Is Empty",
                    systemImage: "cart",
                    description: Text("Add missing ingredients from a recipe's detail screen to build your list.")
                )
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        Button {
                            viewModel.toggleCompletion(of: item)
                        } label: {
                            HStack {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .strikethrough(item.isCompleted)
                                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                                    Text(item.formattedQuantity)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.name), \(item.formattedQuantity)")
                        .accessibilityValue(item.isCompleted ? "Bought" : "Not bought")
                        .accessibilityAddTraits(.isButton)
                    }
                    .onDelete(perform: removeItems)
                }
            }
        }
        .navigationTitle("Shopping List")
        .onAppear {
            viewModel.loadItems()
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
        ShoppingListView(viewModel: ShoppingListViewModel())
    }
}
