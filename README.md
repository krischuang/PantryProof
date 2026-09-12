# PantryProof

PantryProof is an offline iOS app that helps a home cook answer one question: **"Can I still make this recipe with what's in my fridge and pantry right now?"**

PantryProof builds on the FridgeFix concept developed in Assessment 1, with the product name refined to better reflect its focus on pantry accuracy and recipe feasibility.

## Project Overview

PantryProof compares a recipe's ingredient requirements against the home cook's current pantry and gives a single, trustworthy answer - ready to cook, can make with adjustments, or blocked - along with exactly why, ingredient by ingredient. Everything runs locally from in-memory sample data: there is no network layer, no backend, and no AI-generated guidance, so the same recipe and pantry combination always produces the same result. The app answers whether a recipe the cook has already chosen is feasible with what they actually own - it is not a meal recommendation or recipe-ranking system that decides what to cook.

## Domain Context

A home cook rarely has every ingredient a recipe calls for, and deciding whether that actually matters takes real judgement: running out of the centrepiece protein is not the same situation as running out of a garnish, and "I have some, but maybe not enough" is different again from "I don't have any." PantryProof encodes that judgement as an explicit, testable set of rules rather than leaving the cook to work it out from a plain ingredient list.

## Primary Stakeholder

The home cook deciding, in the moment, whether tonight's recipe is actually achievable - not a professional chef, not a meal-planning power user. The app is designed around a single fast loop: open a recipe, get a verdict, act on it.

## Why This Is a Business Domain, Not a Demo App

PantryProof doesn't have an institutional stakeholder the way a hospital ward or claims department does - its business context is grocery-tech and retail: the same category of problem grocery-delivery apps, meal-kit services, and supermarket loyalty platforms build product teams around (Woolworths' shopping list, Instacart's pantry tracking, and HelloFresh's ingredient logic are all commercial products solving a version of this exact problem). What makes an app a *business* application isn't who the stakeholder is, it's how the software is built: every decision here is driven by domain rules with real consequences if they're wrong. A cook who trusts a false "ready to cook" verdict wastes a shopping trip or discovers a missing ingredient mid-recipe; a duplicate-handling bug that silently merges two different pantry quantities corrupts the one piece of state the whole app exists to keep trustworthy. PantryProof treats those failure modes with the same discipline the brief's regulated-industry examples demand - typed domain errors instead of generic failures, one explicit business-rule model (`RecipeEvaluation.feasibility`) instead of ad hoc booleans scattered across views, and human-facing recovery paths instead of silent failure - because the underlying engineering problem (turn a domain's real judgement calls into testable, auditable rules) is the same one a claims system or medication tracker solves, just at consumer scale instead of institutional scale.

## Problem Statement

A recipe app that only lists ingredients forces the cook to manually cross-reference it against their pantry, guess whether a partial substitute will work, and separately remember to buy what's missing. PantryProof does that comparison for them, deterministically, and turns "what's missing" directly into shopping-list action.

## Core Features

- **Pantry management** - add, view, and update ingredients on hand (name, quantity, unit, category), with validation and a defined duplicate-handling rule.
- **Recipe browsing** - sample recipes with an at-a-glance feasibility badge.
- **Quantity-aware evaluation** - compares a recipe's requirement against the pantry by *amount*, not just presence, distinguishing **insufficient** from **missing**, and honestly flagging **unverified** when the pantry and recipe use different units PantryProof cannot safely compare.
- **Essential / Replaceable / Optional roles** - every recipe ingredient carries a role that changes how a shortfall is treated.
- **Ingredient substitution** - a deterministic local lookup suggests a pantry-backed substitute where one exists, and checks the substitute's own quantity against the same requirement rather than assuming presence means enough.
- **"Can I still make this?" verdict** - one consistent, contradiction-free `RecipeEvaluation` per recipe.
- **Shopping list** - add missing/insufficient ingredients directly from a recipe evaluation at exactly the quantity still needed (the full amount if missing, only the shortfall if insufficient), with duplicate prevention and completion tracking.

## Architecture

```text
SwiftUI Views
    ↓
ViewModels
    ↓
Use Cases
    ↓
Domain Models / Domain Services / Repository Abstractions
    ↓
Local Data
```

- **Views** render presentation state and forward user intent to a ViewModel. They contain no business rules.
- **ViewModels** (`PantryViewModel`, `RecipeViewModel`, `ShoppingListViewModel`) hold presentation state, call Use Cases, and map results/typed errors into view-friendly values - including `RecipeViewModel.feasibilityGuidance`, which turns a `RecipeEvaluation` into the recovery sentence `RecipeDetailView` renders, so the view never re-interprets the domain result itself. They are `@MainActor` `@Observable` classes and contain no business rules of their own; every significant mutation (add, update, remove, toggle) is delegated to a Use Case, never called directly against a repository.
- **Use Cases** are the only place a business operation is orchestrated end-to-end. Each is a small, dependency-injected `struct` with a single `execute` entry point.
- **Domain Models** (`Recipe`, `PantryItem`, `RecipeEvaluation`, …) are value types. Where a rule is pure and needs no external dependency - like the overall feasibility verdict - it lives as a computed property directly on the model, so every caller (UI, tests, docs) reads the exact same answer.
- **Domain Protocols** (`PantryRepository`, `ShoppingListRepository`, `RecipeRepository`, `SubstitutionProviding`) abstract storage and the substitution lookup so Use Cases never depend on a concrete data source.
- **Data** holds the concrete, in-memory, deterministic implementations of those protocols (`InMemoryPantryRepository`, `InMemoryShoppingListRepository`, `InMemoryRecipeRepository`) and the local substitution rule table (`LocalSubstitutionService`).

## Use Cases

| Use Case | Responsibility | Typed Error |
| --- | --- | --- |
| `EvaluateRecipeFeasibilityUseCase` | The primary operation: compares a recipe against the pantry, ingredient by ingredient, producing a `RecipeEvaluation`. Pure function of its inputs - deterministic and directly unit-testable. | `EvaluateRecipeFeasibilityError` |
| `AddPantryItemUseCase` | Validates a new pantry entry (name, quantity) and enforces the duplicate-ingredient rule before it ever reaches storage. | `AddPantryItemError` |
| `UpdatePantryItemUseCase` | Updates an existing pantry item's quantity - the action `AddPantryItemError.duplicateIngredient`'s message actually points the cook toward. | `AddPantryItemError` / `UpdatePantryItemError` |
| `RemovePantryItemUseCase` | Removes a pantry item the cook has used up, naming "item no longer exists" as a typed failure instead of a silent repository call. | `RemovePantryItemError` |
| `AddMissingIngredientToShoppingListUseCase` | Adds a recipe ingredient to the shopping list at the quantity it's given (computed by `RecipeIngredientEvaluation.shoppingListQuantity` - the caller never invents this number), with duplicate prevention that still allows re-adding a completed item. | `AddMissingIngredientToShoppingListError` |
| `ToggleShoppingListItemUseCase` | Marks a shopping list item bought/unbought, naming the "item no longer exists" failure as a typed error instead of silently no-op'ing. | `ToggleShoppingListItemError` |
| `RemoveShoppingListItemUseCase` | Removes an item from the shopping list at the cook's request, naming "item no longer exists" as a typed failure. | `RemoveShoppingListItemError` |

`AddPantryItemUseCase`, `EvaluateRecipeFeasibilityUseCase` and `AddMissingIngredientToShoppingListUseCase` satisfy the required three; every other Use Case was added because it closes a real gap - an error message the UI couldn't otherwise act on, a genuine not-found failure mode, or a mutation that would otherwise bypass the Use Case layer - not to inflate the count. Every Use Case has a typed `LocalizedError` and both happy-path and failure-path test coverage (see [Testing](#testing)).

## Business Rules

**Availability** (`IngredientAvailability`), for an ingredient the recipe requires:

- Pantry quantity ≥ required quantity → **available**
- Pantry quantity < required quantity, same unit → **insufficient**
- Ingredient not in the pantry at all → **missing**
- Pantry and recipe units differ → **quantity unverified**. PantryProof does not attempt unit conversion (out of scope, and an incorrect conversion would be worse than none), and it never silently reports the quantity as sufficient. It surfaces the pantry's own quantity and unit alongside a plain-language explanation ("You have 500 g, but this recipe measures in tbsp. Check the amount before cooking.") so the cook can judge for themselves.

**Substitute quantity certainty** (`PantrySubstitute.quantityAvailability`, computed in `LocalSubstitutionService`): a substitute being *in* the pantry is not the same claim as a substitute being *enough* - 1 ml of milk doesn't stand in for 100 ml of cream just because milk is technically present. Every substitute is checked against the original ingredient's required quantity using the same comparison the pantry itself uses:

- Substitute quantity ≥ required quantity, same unit → **available** (a real fix).
- Substitute quantity < required quantity, same unit → **insufficient** (present, but doesn't help - see `RecipeIngredientEvaluation.hasUsableSubstitution`, which excludes this case).
- Substitute and recipe units differ → **quantity unverified** (can't be ruled out, but not proven either - no unit conversion is attempted, same rule as pantry-vs-recipe comparison).

**Feasibility** (`RecipeEvaluation.feasibility`), the single rule used everywhere - UI, tests, and this document:

- An **essential or replaceable** ingredient that is missing/insufficient **and has no *usable* substitute** → the recipe is **blocked**. A replaceable ingredient the cook can neither buy nor swap out is exactly as blocking as an essential one, and a substitute that's demonstrably insufficient doesn't count as an escape hatch - that would be false certainty.
- An **essential or replaceable** ingredient that is missing/insufficient **with a usable substitute** (available, or quantity-unverified) → **can make with adjustments**.
- An **essential or replaceable** ingredient with an **unverified quantity** → never blocks the recipe outright (presence is confirmed), but never results in **ready to cook** either (the amount is not confirmed) - it always downgrades to **can make with adjustments**, regardless of whether a substitute exists.
- An **optional** ingredient that is missing/insufficient/unverified → never affects feasibility.
- If *any* ingredient meets the first condition, the recipe is blocked overall, even if another ingredient elsewhere is separately adjustable - PantryProof never reports "can make with adjustments" while something is still genuinely blocking.

**Shopping list quantity** (`RecipeIngredientEvaluation.shoppingListQuantity`): "Add to Shopping List" adds only what's actually still needed, not a blanket re-statement of the recipe's requirement.

- **Missing** entirely → the full required quantity.
- **Insufficient**, same unit as the recipe (guaranteed, by definition of insufficient) → only the shortage (required minus on hand), which is always strictly positive.
- **Quantity unverified** (units differ) → the full required quantity - subtracting across units would be a guess, and PantryProof doesn't guess at quantities.
- **Available** → zero; the UI never offers to add an ingredient that's already covered.

**Pantry duplicates**: adding an ingredient already in the pantry is rejected outright rather than merged or duplicated, so the pantry keeps a "one row per ingredient" invariant. The error explains this and the app provides a direct path to update the existing entry instead.

**Shopping list duplicates**: adding an ingredient already on the list while an *active* (not yet bought) entry exists is a no-op returning that entry. Once an entry is marked bought, it no longer blocks re-adding, since that stock has been used.

## Error and Recovery Design

Every domain error is a typed `LocalizedError` enum with a message written for the cook, not a developer - what happened, and what they can do next:

- `AddPantryItemError` - `emptyIngredientName`, `invalidQuantity`, `duplicateIngredient(name:)` (e.g. *"You already have Chicken in your pantry. Update its quantity instead of adding it again."*)
- `UpdatePantryItemError` - `itemNotFound`
- `RemovePantryItemError` - `pantryItemNotFound`
- `ToggleShoppingListItemError` - `itemNotFound`
- `RemoveShoppingListItemError` - `itemNotFound`
- `AddMissingIngredientToShoppingListError` - `invalidRequiredQuantity` (a zero or negative required quantity is not a meaningful shopping list entry)
- `EvaluateRecipeFeasibilityError` - `recipeHasNoIngredients` (a recipe with no ingredient requirements cannot be meaningfully evaluated); `RecipeDetailView` pairs this message with a direct "Back to Recipes" action instead of leaving the cook stranded on an unusable screen

Where an error names a next action, the UI provides it directly: the duplicate-ingredient error's "update its quantity instead" is backed by a real edit flow (`UpdatePantryItemView`), reachable both by tapping a pantry row and directly from the error itself. `RecipeDetailView`'s feasibility banner carries one sentence of concrete guidance sourced from `RecipeViewModel.feasibilityGuidance`, mapped from the same evaluation shown below it, so the guidance can never contradict the ingredient list. The same principle covers quantity uncertainty: an ingredient PantryProof cannot verify never gets a raw "unit mismatch" message - it gets the pantry's own quantity plus a concrete next step ("check the amount before cooking").

## Testing

78 tests across four areas, all passing via `xcodebuild test`:

- **`PantryProofTests/UseCases/`** - `EvaluateRecipeFeasibilityUseCaseTests` (20, including substitute-quantity-certainty cases against the real `LocalSubstitutionService`), `AddPantryItemUseCaseTests` (6), `UpdatePantryItemUseCaseTests` (3), `RemovePantryItemUseCaseTests` (2), `AddMissingIngredientToShoppingListUseCaseTests` (6), `ToggleShoppingListItemUseCaseTests` (3), `RemoveShoppingListItemUseCaseTests` (2).
- **`PantryProofTests/Domain/`** - `RecipeEvaluationTests` (11), exercising the feasibility rule directly against hand-built rows - including the quantity-unverified and usable-substitution rules - independent of pantry-matching; `RecipeIngredientEvaluationTests` (5), exercising `shoppingListQuantity` directly.
- **`PantryProofTests/Services/`** - `LocalSubstitutionServiceTests` (5), verifying a substitute's `quantityAvailability` reflects whether the pantry has *enough* of it, not just whether it's present.
- **`PantryProofTests/ViewModels/`** - `PantryViewModelTests` (8), `ShoppingListViewModelTests` (5), `RecipeViewModelTests` (2), verifying view models correctly surface use case results/errors, delegate every mutation to a Use Case, and never duplicate business logic.

Test names describe business behaviour (e.g. `test_evaluateRecipe_blocksCooking_whenEssentialIngredientIsMissingWithNoSubstitute`), and every use case has both happy-path and failure-path coverage.

## Project Structure

```text
PantryProof/
├── App/                    PantryProofApp entry point
├── Domain/
│   ├── Models/              Ingredient, PantryItem, Recipe, RecipeIngredient,
│   │                        IngredientRole, IngredientAvailability,
│   │                        PantrySubstitute, RecipeEvaluation,
│   │                        RecipeFeasibility, ShoppingListItem
│   ├── Errors/               AddPantryItemError, UpdatePantryItemError,
│   │                        RemovePantryItemError, ToggleShoppingListItemError,
│   │                        RemoveShoppingListItemError,
│   │                        AddMissingIngredientToShoppingListError,
│   │                        EvaluateRecipeFeasibilityError
│   └── Protocols/            PantryRepository, ShoppingListRepository,
│                            RecipeRepository, SubstitutionProviding
├── UseCases/                EvaluateRecipeFeasibilityUseCase, AddPantryItemUseCase,
│                            UpdatePantryItemUseCase, RemovePantryItemUseCase,
│                            AddMissingIngredientToShoppingListUseCase,
│                            ToggleShoppingListItemUseCase, RemoveShoppingListItemUseCase
├── Services/                 LocalSubstitutionService
├── Data/                     InMemoryPantryRepository, InMemoryShoppingListRepository,
│                            InMemoryRecipeRepository
├── ViewModels/                PantryViewModel, RecipeViewModel, ShoppingListViewModel
├── Views/
│   ├── Home/                 HomeView
│   ├── Pantry/                PantryView, AddPantryItemView, UpdatePantryItemView
│   ├── Recipes/               RecipeListView, RecipeDetailView
│   └── ShoppingList/          ShoppingListView
└── Resources/
    └── PantryProof.docc/        DocC landing article for the domain layer

PantryProofTests/
├── UseCases/
├── Domain/
├── Services/
└── ViewModels/
```

## Setup Instructions

1. Open `PantryProof.xcodeproj` in Xcode 26 or later.
2. Select the `PantryProof` scheme.
3. Build and run on an iOS Simulator (iOS 26.1+) or device.
4. Run the `PantryProofTests` target (`Cmd+U`) to execute the unit test suite.

No external dependencies, API keys, or network access are required - PantryProof runs entirely from local sample data.
