# FridgeFix — Assessment Compliance

This file maps every requirement of the Assessment 2 brief to concrete
evidence in this repository. Nothing below is marked PASS without a file,
test, or documented decision backing it.

| Requirement | Code Evidence | Test Evidence | Documentation Evidence | Status |
| --- | --- | --- | --- | --- |
| New project, not a copy of the old one | `git log --oneline` root commit `chore: initialise FridgeFix iOS project`, built from the Xcode SwiftUI template, no old-project files imported | — | README setup instructions | PASS |
| Domain-centred architecture (Views → ViewModels → Use Cases → Domain/Services → Data) | `FridgeFix/{Views,ViewModels,UseCases,Domain,Services,Data}` folder structure | — | README "Architecture" section; `docs/ARCHITECTURE_DIAGRAM.md` | PASS |
| ≥3 genuine Use Cases | `EvaluateRecipeFeasibilityUseCase.swift`, `AddPantryItemUseCase.swift`, `AddMissingIngredientToShoppingListUseCase.swift` (required three); `UpdatePantryItemUseCase.swift`, `ToggleShoppingListItemUseCase.swift` (justified optional additions) | 12 + 6 + 4 + 3 + 3 = 28 use case tests | README "Use Cases" table | PASS |
| Domain models use semantic, non-vague names | `Ingredient`, `PantryItem`, `Recipe`, `RecipeIngredient`, `IngredientRole`, `IngredientAvailability`, `IngredientSubstitution`, `RecipeEvaluation`, `RecipeFeasibility`, `ShoppingListItem` — no `Item`/`Manager`/`Handler` types | — | DocC comments on every model (`FridgeFix.docc/FridgeFix.md` + inline `///`) | PASS |
| `struct` for domain records | All 10 domain model files are `struct`; only repositories/services (`InMemoryPantryRepository`, `InMemoryShoppingListRepository`, `InMemoryRecipeRepository`, `LocalSubstitutionService`) and ViewModels are reference types, each for a stated reason (shared mutable storage; SwiftUI observation) | — | README architecture note; inline doc comments | PASS |
| `IngredientRole` (essential/replaceable/optional) | `Domain/Models/RecipeIngredient.swift` | `RecipeEvaluationTests.test_feasibility_ignoresOptionalIngredients_*` | README "Business Rules" | PASS |
| `IngredientAvailability` (available/insufficient/missing) | `Domain/Models/IngredientAvailability.swift` | `EvaluateRecipeFeasibilityUseCaseTests` (exact/greater/lower quantity, missing) | README "Business Rules" | PASS |
| `RecipeFeasibility` (readyToCook/canMakeWithAdjustments/blocked) | `Domain/Models/RecipeFeasibility.swift` | `RecipeEvaluationTests`, `EvaluateRecipeFeasibilityUseCaseTests` | README "Business Rules" | PASS |
| Recipe feasibility rules match brief exactly, no contradictions | `Domain/Models/RecipeEvaluation.swift` (`feasibility` computed property — single source of truth) | `test_feasibility_prefersBlocked_whenBothUnresolvedAndAdjustableIngredientsExist` | `docs/REFLECTIVE_REPORT.md` "Domain understanding" | PASS |
| Typed domain errors with human-facing messages | `AddPantryItemError`, `UpdatePantryItemError`, `ToggleShoppingListItemError` (all `LocalizedError`) | `AddPantryItemUseCaseTests`, `UpdatePantryItemUseCaseTests`, `ToggleShoppingListItemUseCaseTests`, `PantryViewModelTests`, `ShoppingListViewModelTests` | README "Error and Recovery Design" | PASS |
| Errors explain what happened + next action | e.g. `AddPantryItemError.duplicateIngredient` message; `UpdatePantryItemView` reachable directly from that error | `test_pantryViewModel_addItem_exposesDuplicateItem_forGuidedRecovery` | README error table; reflective report | PASS |
| ≥4 functional SwiftUI screens | `HomeView`, `PantryView`, `RecipeListView`, `RecipeDetailView`, `ShoppingListView` (5, plus supporting forms `AddPantryItemView`/`UpdatePantryItemView`) | Verified via `xcodebuild build` + Simulator launch/screenshot | README "Project Structure" | PASS |
| RecipeDetailView shows role, availability, substitutions, verdict | `Views/Recipes/RecipeDetailView.swift` | Backed by `EvaluateRecipeFeasibilityUseCaseTests` (data) | README "Core Features" | PASS |
| Add missing ingredients to Shopping List from Recipe Detail | `IngredientEvaluationRow.onAddToShoppingList` → `ShoppingListViewModel.addMissingIngredient` | `AddMissingIngredientToShoppingListUseCaseTests` | README "Core Features" | PASS |
| ≥8 meaningful tests, happy + failure + boundary paths | 45 tests total across `FridgeFixTests/{UseCases,Domain,ViewModels}` | `xcodebuild test` — 45/45 passing | README "Testing" | PASS |
| Test names describe business behaviour | e.g. `test_evaluateRecipe_blocksCooking_whenEssentialIngredientIsMissingWithNoSubstitute` | All 45 test files | — | PASS |
| Views contain no significant business logic | Views only read ViewModel state and call ViewModel methods; all validation/feasibility/duplicate logic lives in `UseCases`/`Domain` | — | README architecture section | PASS |
| Meaningful DocC on models and use cases | `///` doc comments on every type in `Domain/Models`, `Domain/Errors`, `Domain/Protocols`, `UseCases`; `FridgeFix.docc/FridgeFix.md` landing article (verified with `xcodebuild docbuild`) | — | — | PASS |
| Complete README | `README.md` — all 12 required sections present | — | — | PASS |
| Human-System Architecture Diagram | `docs/ARCHITECTURE_DIAGRAM.md` + `docs/layer-diagram.png` + `docs/human-system-diagram.png` | — | — | PASS |
| 600–800 word reflective report | `docs/REFLECTIVE_REPORT.md` (719 words) | — | — | PASS |
| Professional Git history, feature branches, Conventional Commits | 8 feature/docs branches, each merged with `--no-ff`; every commit prefixed `feat:`/`fix:`/`test:`/`docs:`/`chore:` | `git log --oneline --graph` | this file | PASS |
| Incremental commits and pushes, no giant final commit | Largest single commit is the Phase 5 `RecipeDetailView` add (~154 lines); every phase pushed after each commit | `git log` per branch | — | PASS |
| Stable main branch | `main` only receives `--no-ff` merges after build + full test pass on the feature branch | `git log main --oneline --graph` | — | PASS |

## Known, disclosed limitations

- **UI walkthrough beyond the Home screen was verified by build success and full ViewModel/UseCase test coverage, not by interactive on-device screenshots of every screen.** The sandboxed CI-like environment this was built in has no macOS Accessibility permission for automated tap simulation (`osascript`/System Events), and adding a dedicated XCUITest target was judged out of scope for this assessment. The Home screen was confirmed visually with live wired data (see session screenshot); Pantry, Recipe List, Recipe Detail, and Shopping List all build successfully and are backed by fully unit-tested ViewModels/UseCases exercising the same logic each screen renders.
- **No persistence across app launches.** Deliberate MVP scope (see `docs/REFLECTIVE_REPORT.md` "What I would do next") — every repository is in-memory, so the pantry and shopping list reset each run. This keeps demos reproducible but is the most realistic next step.
- **No unit conversion between measurement units.** Deliberate, documented scope limitation (see README "Business Rules") rather than an oversight — an incorrect conversion was judged worse than an honest fallback.
