//
//  UpdatePantryItemView.swift
//  FridgeFix
//

import SwiftUI

/// A form for updating an existing pantry item's quantity, presented as a
/// sheet from ``PantryView`` — either by tapping the item directly, or by
/// following the "update its quantity instead" guidance in a duplicate
/// ingredient error.
struct UpdatePantryItemView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: PantryViewModel
    let item: PantryItem

    @State private var quantityText: String
    @State private var unit: MeasurementUnit

    init(viewModel: PantryViewModel, item: PantryItem) {
        self.viewModel = viewModel
        self.item = item
        _quantityText = State(initialValue: item.formattedQuantity.components(separatedBy: " ").first ?? "")
        _unit = State(initialValue: item.unit)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(item.name) {
                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Quantity")
                    Picker("Unit", selection: $unit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Update Quantity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let quantity = Double(quantityText) ?? -1
        viewModel.updateQuantity(for: item, quantity: quantity, unit: unit)
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
