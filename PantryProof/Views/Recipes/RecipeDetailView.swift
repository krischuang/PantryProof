//
//  RecipeDetailView.swift
//  PantryProof
//

import SwiftUI

/// PantryProof's central screen: the verdict for one recipe, plus why,
/// ingredient by ingredient.
///
/// Just renders `recipeViewModel.evaluation` - doesn't compute anything
/// itself. Every rule shown here comes from
/// `EvaluateRecipeFeasibilityUseCase` via `RecipeEvaluation`.
struct RecipeDetailView: View {
    let recipe: Recipe
    var recipeViewModel: RecipeViewModel
    var shoppingListViewModel: ShoppingListViewModel

    var body: some View {
        List {
            Section {
                Text(recipe.summary)
                    .foregroundStyle(.secondary)
                if let evaluation = recipeViewModel.evaluation, let guidance = recipeViewModel.feasibilityGuidance {
                    FeasibilityBanner(feasibility: evaluation.feasibility, guidance: guidance)
                        .listRowInsets(EdgeInsets())
                } else if let errorMessage = recipeViewModel.errorMessage {
                    InlineErrorBanner(message: errorMessage)
                        .listRowInsets(EdgeInsets())
                }
            }

            if let evaluation = recipeViewModel.evaluation {
                Section("Ingredients") {
                    ForEach(evaluation.evaluatedIngredients) { evaluatedIngredient in
                        IngredientEvaluationRow(
                            evaluatedIngredient: evaluatedIngredient,
                            onAddToShoppingList: {
                                shoppingListViewModel.addMissingIngredient(
                                    evaluatedIngredient.ingredient,
                                    quantity: evaluatedIngredient.recipeIngredient.quantity,
                                    unit: evaluatedIngredient.recipeIngredient.unit
                                )
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recipeViewModel.evaluate(recipe)
        }
    }
}

/// The feasibility verdict plus one line of guidance, so the cook knows
/// not just what happened but what to do next.
///
/// Purely a rendering of state already decided elsewhere - just picks a
/// colour for the verdict it's given.
private struct FeasibilityBanner: View {
    let feasibility: RecipeFeasibility
    let guidance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(feasibility.title, systemImage: feasibility.symbolName)
                .font(.headline)
                .foregroundStyle(feasibility.color)
            Text(guidance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feasibility.color.opacity(0.12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feasibility: \(feasibility.title). \(guidance)")
    }
}

private struct IngredientEvaluationRow: View {
    let evaluatedIngredient: RecipeIngredientEvaluation
    let onAddToShoppingList: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: evaluatedIngredient.availability.symbolName)
                    .foregroundStyle(evaluatedIngredient.availability.color)
                    .accessibilityHidden(true)
                Text(evaluatedIngredient.ingredient.name)
                    .font(.body)
                Spacer()
                TagBadge(
                    text: evaluatedIngredient.role.displayName,
                    systemImage: evaluatedIngredient.role.symbolName,
                    tint: evaluatedIngredient.role.tint
                )
            }

            requirementLine
                .font(.caption)
                .foregroundStyle(.secondary)

            if !evaluatedIngredient.substitutions.isEmpty {
                Label("Substitute with \(substitutionNames)", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.indigo)
            }

            if evaluatedIngredient.availability != .available {
                Button {
                    onAddToShoppingList()
                } label: {
                    Label("Add to Shopping List", systemImage: "cart.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.blue)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var requirementLine: some View {
        switch evaluatedIngredient.availability {
        case .available:
            Text("Needs \(evaluatedIngredient.recipeIngredient.formattedQuantity) - available")
        case .insufficient:
            Text("You have \(evaluatedIngredient.formattedPantryQuantity ?? "0"), but this recipe needs \(evaluatedIngredient.recipeIngredient.formattedQuantity).")
        case .missing:
            Text("Needs \(evaluatedIngredient.recipeIngredient.formattedQuantity) - not in your pantry.")
        case .quantityUnverified:
            Text("You have \(evaluatedIngredient.formattedPantryQuantity ?? "some"), but this recipe measures in \(evaluatedIngredient.recipeIngredient.unit.symbol). Check the amount before cooking.")
        }
    }

    private var substitutionNames: String {
        evaluatedIngredient.substitutions.map(\.substitute.name).joined(separator: ", ")
    }
}

#Preview {
    let pantryRepository = InMemoryPantryRepository()
    let recipe = InMemoryRecipeRepository.sampleRecipes[1]
    NavigationStack {
        RecipeDetailView(
            recipe: recipe,
            recipeViewModel: RecipeViewModel(pantryRepository: pantryRepository),
            shoppingListViewModel: ShoppingListViewModel()
        )
    }
}
