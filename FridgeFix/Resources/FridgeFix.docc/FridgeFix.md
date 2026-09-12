# ``FridgeFix``

Help a home cook answer one question: "Can I still make this recipe with
what I currently have?"

## Overview

FridgeFix compares a ``Recipe``'s requirements against the home cook's
``PantryItem`` inventory and produces one ``RecipeEvaluation`` - the same
evaluation the UI renders, the tests check, and this doc describes. The
feasibility rule is defined in exactly one place
(``RecipeEvaluation/feasibility``), so the app can't give contradictory
advice.

### Ingredient vs. quantity

``Ingredient`` is just identity - a name and a category, no quantity. A
quantity only exists once you put an ingredient somewhere: in the pantry
(``PantryItem``) or on a recipe (``RecipeIngredient``). Both of those
*have an* `Ingredient` rather than subclassing it - "500 g of chicken" is
an ingredient plus an amount, not a kind of chicken.

### Role decides how "missing" is handled

Every ``RecipeIngredient`` carries an ``IngredientRole``:

- **essential** - central to the dish. Missing or insufficient blocks the
  recipe unless a substitute is available.
- **replaceable** - changes the dish but isn't the star. Same rule as
  essential - no substitute means it's just as blocking.
- **optional** - a garnish or enhancement. Never blocks the recipe.

A replaceable ingredient isn't automatically "safe to skip" just because
it's replaceable - it only stays out of the way once a real substitute is
actually sitting in the pantry.

### Availability is four states, not two

``IngredientAvailability`` splits ``IngredientAvailability/missing`` (not
in the pantry) from ``IngredientAvailability/insufficient`` (in the
pantry, just not enough) - a cook with 200 g of chicken for a 400 g
requirement is in a different spot than a cook with none, and the recipe
screen's "Have / Need" comparison needs that distinction. The fourth
state, ``IngredientAvailability/quantityUnverified``, covers the case
where the pantry and recipe use different units and the amounts can't be
safely compared. Rather than guess and risk a wrong "available", FridgeFix
reports it as unverified and shows the cook what's actually on hand. An
unverified essential/replaceable ingredient never blocks a recipe outright
(it's there), but never counts as ready to cook either (the amount's not
confirmed).

### One feasibility rule, everywhere

``RecipeEvaluation/feasibility`` turns the evaluated ingredient rows into
one ``RecipeFeasibility`` - ``RecipeFeasibility/readyToCook``,
``RecipeFeasibility/canMakeWithAdjustments``, or
``RecipeFeasibility/blocked``. It's a pure computed property with no
dependencies, which is what makes it easy to test and the same everywhere
it's used.

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
- ``PantrySubstitute``
- ``RecipeIngredientEvaluation``
- ``RecipeEvaluation``
- ``RecipeFeasibility``
