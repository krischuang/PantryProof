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
    @Environment(\.dismiss) private var dismiss
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
                    Button {
                        dismiss()
                    } label: {
                        Label("Back to Recipes", systemImage: "chevron.backward")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }

            if let evaluation = recipeViewModel.evaluation {
                Section("Ingredients") {
                    ForEach(evaluation.evaluatedIngredients) { evaluatedIngredient in
                        IngredientEvaluationRow(
                            evaluatedIngredient: evaluatedIngredient,
                            isAlreadyOnShoppingList: shoppingListViewModel.items.contains {
                                !$0.isCompleted && $0.ingredient.matches(evaluatedIngredient.ingredient)
                            },
                            onAddToShoppingList: {
                                shoppingListViewModel.addMissingIngredient(
                                    evaluatedIngredient.ingredient,
                                    quantity: evaluatedIngredient.shoppingListQuantity,
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
    let isAlreadyOnShoppingList: Bool
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
                Label(substitutionMessage, systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(evaluatedIngredient.hasUsableSubstitution ? .indigo : .orange)
            }

            if evaluatedIngredient.availability != .available {
                if isAlreadyOnShoppingList {
                    Label("Already on Shopping List", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
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

    /// Names each substitute honestly instead of implying every listed
    /// substitute is a sure thing: a name on its own means the pantry has
    /// enough, "check amount" means the units didn't match so PantryProof
    /// can't confirm, and "not enough on hand" means the pantry quantity is
    /// demonstrably short.
    private var substitutionMessage: String {
        let names = evaluatedIngredient.substitutions.map { substitute -> String in
            switch substitute.quantityAvailability {
            case .available:
                return substitute.substitute.name
            case .quantityUnverified:
                return "\(substitute.substitute.name) (check amount)"
            case .insufficient, .missing:
                return "\(substitute.substitute.name) (not enough on hand)"
            }
        }
        return "Substitute with \(names.joined(separator: ", "))"
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
