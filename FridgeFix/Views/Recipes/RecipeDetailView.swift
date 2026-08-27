//
//  RecipeDetailView.swift
//  FridgeFix
//

import SwiftUI

/// FridgeFix's central screen: answers "can I still make this?" for one
/// recipe by showing the overall verdict alongside exactly why, ingredient
/// by ingredient.
///
/// This view renders `recipeViewModel.evaluation` — it does not compare
/// ingredients or compute feasibility itself. Every rule the cook sees here
/// (available/insufficient/missing, essential/replaceable/optional,
/// substitution guidance, the overall verdict) comes from
/// `EvaluateRecipeFeasibilityUseCase` by way of `RecipeEvaluation`.
struct RecipeDetailView: View {
    let recipe: Recipe
    var recipeViewModel: RecipeViewModel
    var shoppingListViewModel: ShoppingListViewModel

    var body: some View {
        List {
            Section {
                Text(recipe.summary)
                    .foregroundStyle(.secondary)
                if let evaluation = recipeViewModel.evaluation {
                    FeasibilityBanner(evaluation: evaluation)
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
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recipeViewModel.evaluate(recipe)
        }
    }
}

/// The feasibility verdict plus one sentence of recovery guidance, so the
/// cook always knows not just *what* FridgeFix decided but *what to do
/// next* — the same principle applied to every error message in the app.
private struct FeasibilityBanner: View {
    let evaluation: RecipeEvaluation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(evaluation.feasibility.title, systemImage: evaluation.feasibility.symbolName)
                .font(.headline)
                .foregroundStyle(color)
            Text(guidance)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feasibility: \(evaluation.feasibility.title). \(guidance)")
    }

    private var color: Color {
        switch evaluation.feasibility {
        case .readyToCook: return .green
        case .canMakeWithAdjustments: return .orange
        case .blocked: return .red
        }
    }

    /// A concrete next step, derived from the same evaluation the banner's
    /// verdict came from — never a generic message that could disagree
    /// with what's shown below.
    private var guidance: String {
        switch evaluation.feasibility {
        case .readyToCook:
            return "Everything this recipe needs is already in your pantry."
        case .canMakeWithAdjustments:
            let names = evaluation.missingIngredients
                .filter { $0.hasSubstitution }
                .map(\.ingredient.name)
            return "Use a substitute for \(names.joined(separator: ", ")) — see the ingredient list below."
        case .blocked:
            let unresolved = evaluation.missingIngredients.filter { !$0.hasSubstitution && $0.role != .optional }
            let names = unresolved.map(\.ingredient.name)
            return "\(names.joined(separator: ", ")) — no substitute available. Add to your shopping list below."
        }
    }
}

private struct IngredientEvaluationRow: View {
    let evaluatedIngredient: RecipeIngredientEvaluation
    let onAddToShoppingList: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: evaluatedIngredient.availability.symbolName)
                    .foregroundStyle(availabilityColor)
                    .accessibilityHidden(true)
                Text(evaluatedIngredient.ingredient.name)
                    .font(.body)
                Spacer()
                Text(evaluatedIngredient.role.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.thinMaterial, in: Capsule())
            }

            requirementLine

            if !evaluatedIngredient.substitutions.isEmpty {
                Text("Substitute with: \(substitutionNames)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if evaluatedIngredient.availability != .available {
                Button("Add to Shopping List", action: onAddToShoppingList)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var requirementLine: some View {
        switch evaluatedIngredient.availability {
        case .available:
            Text("Needs \(evaluatedIngredient.recipeIngredient.formattedQuantity) — available")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .insufficient:
            Text("You have \(evaluatedIngredient.formattedPantryQuantity ?? "0"), but this recipe needs \(evaluatedIngredient.recipeIngredient.formattedQuantity).")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .missing:
            Text("Needs \(evaluatedIngredient.recipeIngredient.formattedQuantity) — not in your pantry.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var substitutionNames: String {
        evaluatedIngredient.substitutions.map(\.substitute.name).joined(separator: ", ")
    }

    private var availabilityColor: Color {
        switch evaluatedIngredient.availability {
        case .available: return .green
        case .insufficient: return .orange
        case .missing: return .red
        }
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
