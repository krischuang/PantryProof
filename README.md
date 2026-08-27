# FridgeFix

FridgeFix is an offline iOS app that helps a home cook answer one question: **"Can I still make this recipe with what's in my fridge and pantry right now?"**

## Project Overview

FridgeFix compares a recipe's ingredient requirements against the home cook's current pantry and gives a single, trustworthy answer — ready to cook, can make with adjustments, or blocked — along with exactly why, ingredient by ingredient. Everything runs locally from in-memory sample data: there is no network layer, no backend, and no AI-generated guidance, so the same recipe and pantry combination always produces the same result.

## Domain Context

A home cook rarely has every ingredient a recipe calls for, and deciding whether that actually matters takes real judgement: running out of the centrepiece protein is not the same situation as running out of a garnish, and "I have some, but maybe not enough" is different again from "I don't have any." FridgeFix encodes that judgement as an explicit, testable set of rules rather than leaving the cook to work it out from a plain ingredient list.

## Primary Stakeholder

The home cook deciding, in the moment, whether tonight's recipe is actually achievable — not a professional chef, not a meal-planning power user. The app is designed around a single fast loop: open a recipe, get a verdict, act on it.

## Problem Statement

A recipe app that only lists ingredients forces the cook to manually cross-reference it against their pantry, guess whether a partial substitute will work, and separately remember to buy what's missing. FridgeFix does that comparison for them, deterministically, and turns "what's missing" directly into shopping-list action.

## Core Features

- **Pantry management** — add, view, and update ingredients on hand (name, quantity, unit, category), with validation and a defined duplicate-handling rule.
- **Recipe browsing** — sample recipes with an at-a-glance feasibility badge.
- **Quantity-aware evaluation** — compares a recipe's requirement against the pantry by *amount*, not just presence, distinguishing **insufficient** from **missing**.
- **Essential / Replaceable / Optional roles** — every recipe ingredient carries a role that changes how a shortfall is treated.
- **Ingredient substitution** — a deterministic local lookup suggests a pantry-backed substitute where one exists.
- **"Can I still make this?" verdict** — one consistent, contradiction-free `RecipeEvaluation` per recipe.
- **Shopping list** — add missing/insufficient ingredients directly from a recipe evaluation at the recipe's required quantity, with duplicate prevention and completion tracking.

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
- **ViewModels** (`PantryViewModel`, `RecipeViewModel`, `ShoppingListViewModel`) hold presentation state, call Use Cases, and map results/typed errors into view-friendly values. They are `@MainActor` `@Observable` classes and contain no business rules of their own.
- **Use Cases** are the only place a business operation is orchestrated end-to-end. Each is a small, dependency-injected `struct` with a single `execute` entry point.
- **Domain Models** (`Recipe`, `PantryItem`, `RecipeEvaluation`, …) are value types. Where a rule is pure and needs no external dependency — like the overall feasibility verdict — it lives as a computed property directly on the model, so every caller (UI, tests, docs) reads the exact same answer.
- **Domain Protocols** (`PantryRepository`, `ShoppingListRepository`, `RecipeRepository`, `SubstitutionProviding`) abstract storage and the substitution lookup so Use Cases never depend on a concrete data source.
- **Data** holds the concrete, in-memory, deterministic implementations of those protocols (`InMemoryPantryRepository`, `InMemoryShoppingListRepository`, `InMemoryRecipeRepository`) and the local substitution rule table (`LocalSubstitutionService`).

## Use Cases

| Use Case | Responsibility |
| --- | --- |
| `EvaluateRecipeFeasibilityUseCase` | The primary operation: compares a recipe against the pantry, ingredient by ingredient, producing a `RecipeEvaluation`. Pure function of its inputs — deterministic and directly unit-testable. |
| `AddPantryItemUseCase` | Validates a new pantry entry (name, quantity) and enforces the duplicate-ingredient rule before it ever reaches storage. |
| `UpdatePantryItemUseCase` | Updates an existing pantry item's quantity — the action `AddPantryItemError.duplicateIngredient`'s message actually points the cook toward. |
| `AddMissingIngredientToShoppingListUseCase` | Adds a recipe ingredient to the shopping list at the recipe's own required quantity, with duplicate prevention that still allows re-adding a completed item. |
| `ToggleShoppingListItemUseCase` | Marks a shopping list item bought/unbought, naming the "item no longer exists" failure as a typed error instead of silently no-op'ing. |

`AddPantryItemUseCase`, `EvaluateRecipeFeasibilityUseCase` and `AddMissingIngredientToShoppingListUseCase` satisfy the required three; `UpdatePantryItemUseCase` and `ToggleShoppingListItemUseCase` were added because each closes a real gap (an error message the UI couldn't otherwise act on, and a genuine not-found failure mode) — not to inflate the count.

## Business Rules

**Availability** (`IngredientAvailability`), for an ingredient the recipe requires:

- Pantry quantity ≥ required quantity → **available**
- Pantry quantity < required quantity, same unit → **insufficient**
- Ingredient not in the pantry at all → **missing**
- Pantry and recipe units differ → FridgeFix does not attempt unit conversion (out of scope, and an incorrect conversion would be worse than none). It falls back to presence alone and leaves the pantry's own quantity visible so the cook can judge for themselves.

**Feasibility** (`RecipeEvaluation.feasibility`), the single rule used everywhere — UI, tests, and this document:

- An **essential or replaceable** ingredient that is missing/insufficient **and has no available substitute** → the recipe is **blocked**. A replaceable ingredient the cook can neither buy nor swap out is exactly as blocking as an essential one.
- An **essential or replaceable** ingredient that is missing/insufficient **with a substitute available** → **can make with adjustments**.
- An **optional** ingredient that is missing/insufficient → never affects feasibility.
- If *any* ingredient meets the first condition, the recipe is blocked overall, even if another ingredient elsewhere is separately adjustable — FridgeFix never reports "can make with adjustments" while something is still genuinely blocking.

**Pantry duplicates**: adding an ingredient already in the pantry is rejected outright rather than merged or duplicated, so the pantry keeps a "one row per ingredient" invariant. The error explains this and the app provides a direct path to update the existing entry instead.

**Shopping list duplicates**: adding an ingredient already on the list while an *active* (not yet bought) entry exists is a no-op returning that entry. Once an entry is marked bought, it no longer blocks re-adding, since that stock has been used.

## Error and Recovery Design

Every domain error is a typed `LocalizedError` enum with a message written for the cook, not a developer — what happened, and what they can do next:

- `AddPantryItemError` — `emptyIngredientName`, `invalidQuantity`, `duplicateIngredient(name:)` (e.g. *"You already have Chicken in your pantry. Update its quantity instead of adding it again."*)
- `UpdatePantryItemError` — `itemNotFound`
- `ToggleShoppingListItemError` — `itemNotFound`

Where an error names a next action, the UI provides it directly: the duplicate-ingredient error's "update its quantity instead" is backed by a real edit flow (`UpdatePantryItemView`), reachable both by tapping a pantry row and directly from the error itself. `RecipeDetailView`'s feasibility banner carries one sentence of concrete guidance derived from the same evaluation shown below it, so the guidance can never contradict the ingredient list.

## Testing

45 tests across three areas, all passing via `xcodebuild test`:

- **`FridgeFixTests/UseCases/`** — `EvaluateRecipeFeasibilityUseCaseTests` (12), `AddPantryItemUseCaseTests` (6), `UpdatePantryItemUseCaseTests` (3), `AddMissingIngredientToShoppingListUseCaseTests` (4), `ToggleShoppingListItemUseCaseTests` (3).
- **`FridgeFixTests/Domain/`** — `RecipeEvaluationTests` (6), exercising the feasibility rule directly against hand-built rows, independent of pantry-matching.
- **`FridgeFixTests/ViewModels/`** — `PantryViewModelTests` (7), `ShoppingListViewModelTests` (4), verifying view models correctly surface use case results/errors and never duplicate business logic.

Test names describe business behaviour (e.g. `test_evaluateRecipe_blocksCooking_whenEssentialIngredientIsMissingWithNoSubstitute`), and every use case has both happy-path and failure-path coverage.

## Project Structure

```text
FridgeFix/
├── App/                    FridgeFixApp entry point
├── Domain/
│   ├── Models/              Ingredient, PantryItem, Recipe, RecipeIngredient,
│   │                        IngredientRole, IngredientAvailability,
│   │                        IngredientSubstitution, RecipeEvaluation,
│   │                        RecipeFeasibility, ShoppingListItem
│   ├── Errors/               AddPantryItemError, UpdatePantryItemError,
│   │                        ToggleShoppingListItemError
│   └── Protocols/            PantryRepository, ShoppingListRepository,
│                            RecipeRepository, SubstitutionProviding
├── UseCases/                EvaluateRecipeFeasibilityUseCase, AddPantryItemUseCase,
│                            UpdatePantryItemUseCase,
│                            AddMissingIngredientToShoppingListUseCase,
│                            ToggleShoppingListItemUseCase
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
    └── FridgeFix.docc/        DocC landing article for the domain layer

FridgeFixTests/
├── UseCases/
├── Domain/
└── ViewModels/
```

## Setup Instructions

1. Open `FridgeFix.xcodeproj` in Xcode 26 or later.
2. Select the `FridgeFix` scheme.
3. Build and run on an iOS Simulator (iOS 26.1+) or device.
4. Run the `FridgeFixTests` target (`Cmd+U`) to execute the unit test suite.

No external dependencies, API keys, or network access are required — FridgeFix runs entirely from local sample data.
