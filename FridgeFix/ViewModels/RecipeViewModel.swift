//
//  RecipeViewModel.swift
//  FridgeFix
//

import Foundation
import Observation

/// Presentation state and actions for browsing recipes and asking
/// FridgeFix's central question — "can I still make this?" — about one of
/// them.
///
/// `RecipeViewModel` never compares ingredients or decides feasibility
/// itself; every evaluation is delegated to
/// ``EvaluateRecipeFeasibilityUseCase``, called against the pantry's
/// current contents at the moment of evaluation so the answer always
/// reflects the latest pantry state. It does map that domain result into
/// display-ready wording (``feasibilityGuidance``) so `RecipeDetailView`
/// never has to re-interpret a `RecipeEvaluation` itself — the domain
/// decides *what* is true, this type decides *how to phrase it*, and the
/// view only renders the result.
@MainActor
@Observable
final class RecipeViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var evaluation: RecipeEvaluation?
    var errorMessage: String?

    private let recipeRepository: RecipeRepository
    private let pantryRepository: PantryRepository
    private let evaluateFeasibilityUseCase: EvaluateRecipeFeasibilityUseCase

    init(
        recipeRepository: RecipeRepository = InMemoryRecipeRepository(),
        pantryRepository: PantryRepository,
        evaluateFeasibilityUseCase: EvaluateRecipeFeasibilityUseCase = EvaluateRecipeFeasibilityUseCase()
    ) {
        self.recipeRepository = recipeRepository
        self.pantryRepository = pantryRepository
        self.evaluateFeasibilityUseCase = evaluateFeasibilityUseCase
        loadRecipes()
    }

    func loadRecipes() {
        recipes = recipeRepository.fetchAll()
    }

    /// Runs the full evaluation for `recipe` and stores it in
    /// ``evaluation`` for the recipe detail screen to render. On failure
    /// (the recipe has no ingredients), ``errorMessage`` is set instead.
    func evaluate(_ recipe: Recipe) {
        errorMessage = nil
        do {
            evaluation = try evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        } catch {
            evaluation = nil
            errorMessage = error.localizedDescription
        }
    }

    /// A cheap, side-effect-free feasibility lookup for list-row badges —
    /// does not touch ``evaluation``, so browsing the recipe list never
    /// disturbs whatever evaluation the detail screen is currently
    /// showing.
    ///
    /// A recipe with no ingredients cannot be evaluated at all; `.blocked`
    /// is the safe default badge for that case, consistent with FridgeFix
    /// never claiming readiness it cannot back up.
    func feasibility(for recipe: Recipe) -> RecipeFeasibility {
        let evaluation = try? evaluateFeasibilityUseCase.execute(recipe: recipe, pantry: pantryRepository.fetchAll())
        return evaluation?.feasibility ?? .blocked
    }

    /// One sentence of concrete recovery guidance for the current
    /// ``evaluation``'s feasibility verdict, derived from that same
    /// evaluation so the wording can never disagree with the ingredient
    /// list rendered alongside it. `nil` when there is no evaluation to
    /// describe.
    var feasibilityGuidance: String? {
        guard let evaluation else { return nil }
        switch evaluation.feasibility {
        case .readyToCook:
            return "Everything this recipe needs is already in your pantry."
        case .canMakeWithAdjustments:
            return adjustmentGuidance(for: evaluation)
        case .blocked:
            return blockedGuidance(for: evaluation)
        }
    }

    private func adjustmentGuidance(for evaluation: RecipeEvaluation) -> String {
        let unresolved = evaluation.missingEssential + evaluation.missingReplaceable
        let substitutable = unresolved.filter { $0.hasSubstitution }.map(\.ingredient.name)
        let unverified = unresolved.filter { $0.availability == .quantityUnverified && !$0.hasSubstitution }.map(\.ingredient.name)

        var sentences: [String] = []
        if !substitutable.isEmpty {
            sentences.append("Use a substitute for \(substitutable.joined(separator: ", ")) — see the ingredient list below.")
        }
        if !unverified.isEmpty {
            sentences.append("Check the amount of \(unverified.joined(separator: ", ")) before cooking — FridgeFix couldn't compare its unit to what the recipe needs.")
        }
        return sentences.joined(separator: " ")
    }

    private func blockedGuidance(for evaluation: RecipeEvaluation) -> String {
        let unresolved = evaluation.missingIngredients.filter { !$0.hasSubstitution && $0.role != .optional }
        let names = unresolved.map(\.ingredient.name)
        return "\(names.joined(separator: ", ")) — no substitute available. Add to your shopping list below."
    }
}
