# ``FridgeFix``

Help a home cook answer one question: "Can I still make this recipe with
what I currently have?"

## Overview

FridgeFix compares a ``Recipe``'s requirements against the home cook's
``PantryItem`` inventory and produces a single, deterministic
``RecipeEvaluation`` — the same evaluation the UI renders, the unit tests
assert against, and this documentation describes. There is exactly one
place the feasibility rule is defined (``RecipeEvaluation/feasibility``),
so the app can never show contradictory guidance.

### Identity, not inheritance

``Ingredient`` models identity only — a name and a category, nothing else.
A quantity only exists once an ingredient is placed in context: sitting in
the pantry (``PantryItem``) or required by a recipe (``RecipeIngredient``).
Both compose an `Ingredient` rather than subclassing it, because "500 g of
chicken" is a pairing of an ingredient with an amount, not a kind of
chicken.

### Role decides how "missing" is handled

Every ``RecipeIngredient`` carries an ``IngredientRole``:

- **essential** — central to the dish. Missing or insufficient blocks the
  recipe unless a substitute is available.
- **replaceable** — meaningfully changes the dish, but is not central to
  it. Missing or insufficient blocks the recipe *unless* a substitute is
  available — a replaceable ingredient the cook can neither buy nor swap
  out is exactly as blocking as an essential one.
- **optional** — a garnish or enhancement. Missing or insufficient never
  blocks the recipe.

This distinction is what stops FridgeFix from giving contradictory advice.
A replaceable ingredient is not automatically "safe to skip" just because
its role says "replaceable" — it only stays out of the cook's way once a
real substitute is confirmed to be sitting in the pantry.

### Availability is three states, not two

``IngredientAvailability`` distinguishes ``IngredientAvailability/missing``
(not in the pantry at all) from ``IngredientAvailability/insufficient``
(in the pantry, but not enough of it). A cook with 200 g of chicken for a
400 g requirement is in a different situation than a cook with none, and
the recipe detail screen's "Have / Need" comparison depends on keeping
those states apart.

### One feasibility rule, everywhere

``RecipeEvaluation/feasibility`` derives a single ``RecipeFeasibility`` —
``RecipeFeasibility/readyToCook``, ``RecipeFeasibility/canMakeWithAdjustments``
or ``RecipeFeasibility/blocked`` — from the already-evaluated ingredient
rows. It is a pure computed property with no external dependencies, which
is what makes it deterministic and directly unit-testable, and why the UI
never needs (or is able) to recompute the verdict differently.

## Topics

### Ingredients and Pantry

- ``Ingredient``
- ``IngredientCategory``
- ``PantryItem``
- ``MeasurementUnit``

### Recipes

- ``Recipe``
- ``RecipeIngredient``
- ``IngredientRole``

### Evaluation

- ``IngredientAvailability``
- ``IngredientSubstitution``
- ``RecipeIngredientEvaluation``
- ``RecipeEvaluation``
- ``RecipeFeasibility``
