//
//  ShoppingListView.swift
//  PantryProof
//

import SwiftUI

/// Shows what the cook still needs to buy. Items are usually added from a
/// recipe evaluation, already filled in with the quantity needed.
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
                            HStack(spacing: 12) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .strikethrough(item.isCompleted)
                                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                                    Text(item.formattedQuantity)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.name), \(item.formattedQuantity)")
                        .accessibilityValue(item.isCompleted ? "Bought" : "Not bought")
                        .accessibilityHint("Double tap to toggle bought")
                        .accessibilityAddTraits(.isButton)
                    }
                    .onDelete(perform: removeItems)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Shopping List")
        .onAppear {
            viewModel.loadItems()
        }
        .alert(
            "Couldn't Complete Action",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.errorMessage = nil }
                }
            )
        ) {
            Button("OK") {
                viewModel.errorMessage = nil
                viewModel.loadItems()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
