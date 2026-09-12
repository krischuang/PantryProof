# PantryProof - Human-System Architecture Diagram

This is a one-page view of how PantryProof is layered, and how a single
end-to-end interaction - the home cook asking "can I still make this?" -
crosses that layering from a human action to a human-readable answer.

## Layer Structure

![Layer structure diagram](layer-diagram.png)

<details>
<summary>Mermaid source</summary>

```mermaid
flowchart TD
    Views["SwiftUI Views\n(HomeView, PantryView, RecipeListView,\nRecipeDetailView, ShoppingListView)"]
    ViewModels["ViewModels\n(PantryViewModel, RecipeViewModel,\nShoppingListViewModel)"]
    UseCases["Use Cases\n(EvaluateRecipeFeasibilityUseCase, AddPantryItemUseCase,\nUpdatePantryItemUseCase, RemovePantryItemUseCase,\nAddMissingIngredientToShoppingListUseCase,\nToggleShoppingListItemUseCase, RemoveShoppingListItemUseCase)"]
    Domain["Domain Models / Domain Services / Repository Abstractions\n(Recipe, PantryItem, RecipeEvaluation, RecipeFeasibility …\nSubstitutionProviding · PantryRepository · ShoppingListRepository · RecipeRepository)"]
    Data["Local Data\n(InMemoryPantryRepository, InMemoryShoppingListRepository,\nInMemoryRecipeRepository, LocalSubstitutionService)"]

    Views --> ViewModels --> UseCases --> Domain --> Data
```

</details>

Business rules live only in the **Use Cases** and **Domain** layers. Views
render state and forward intent; ViewModels hold presentation state and
call use cases, never computing feasibility, validation, or duplicate
rules themselves.

## Human-System Boundary: "Can I still make this?"

![Human-system boundary diagram](human-system-diagram.png)

<details>
<summary>Mermaid source</summary>

```mermaid
flowchart TD
    Cook(["HOME COOK"])
    Action["selects a recipe, asks\n'can I still make this?'"]
    Boundary1["SYSTEM BOUNDARY"]
    View["RecipeDetailView"]
    VM["RecipeViewModel"]
    UC["EvaluateRecipeFeasibilityUseCase"]
    Inputs["Recipe + current Pantry\n(via PantryRepository)\n+ SubstitutionProviding"]
    Domain["Domain evaluation\n(quantity comparison, role rules,\nsubstitution lookup)"]
    Result["RecipeEvaluation\n(availability + role per ingredient,\noverall RecipeFeasibility)"]
    Boundary2["SYSTEM BOUNDARY"]
    Display["Ready to cook /\nCan make with adjustments /\nMissing required ingredients\n+ per-ingredient explanation"]
    Next["chooses next action:\nadd missing items to Shopping List,\nor cook"]

    Cook --> Action --> Boundary1 --> View --> VM --> UC --> Inputs --> Domain --> Result --> VM --> View --> Boundary2 --> Display --> Cook
    Display -.-> Next -.-> Cook
```

</details>

The same `RecipeEvaluation` produced by the use case is what the view
renders - there is no second, independent place where feasibility could be
recomputed differently. If the cook chooses to add a missing ingredient to
the shopping list, that action re-enters the same pattern one layer down:
`RecipeDetailView → ShoppingListViewModel → AddMissingIngredientToShoppingListUseCase → ShoppingListRepository`.

## Rendering this diagram

Both diagrams above are valid [Mermaid](https://mermaid.js.org) syntax and
render natively in GitHub's Markdown preview, in most Markdown-aware
editors, and in the Mermaid Live Editor (https://mermaid.live) for
exporting to PNG/PDF/SVG if a static image is needed for a slide deck or
printed report.
