//
//  AddPantryItemView.swift
//  FridgeFix
//

import SwiftUI

/// A form for adding a new pantry item, presented as a sheet from
/// ``PantryView``.
///
/// This view collects raw input only - every validation and duplicate rule
/// is enforced by ``AddPantryItemUseCase`` via ``PantryViewModel``, not
/// here.
struct AddPantryItemView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: PantryViewModel
    /// Called when the cook chooses to edit the existing duplicate item
    /// instead of adding a new one. The caller is responsible for
    /// dismissing this sheet and presenting an edit flow.
    var onEditExisting: (PantryItem) -> Void

    @State private var name: String = ""
    @State private var quantityText: String = ""
    @State private var unit: MeasurementUnit = .grams
    @State private var category: IngredientCategory = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Ingredient name")
                    Picker("Category", selection: $category) {
                        ForEach(IngredientCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                Section("Quantity") {
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
                        if let duplicateItem = viewModel.duplicateItem {
                            Button("Update Existing Quantity") {
                                onEditExisting(duplicateItem)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Pantry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addItem() }
                }
            }
        }
    }

    private func addItem() {
        let quantity = Double(quantityText) ?? -1
        viewModel.addItem(name: name, quantity: quantity, unit: unit, category: category)
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
