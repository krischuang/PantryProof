# FridgeFix - Reflective Report

## Domain understanding

The single most consequential domain decision in FridgeFix is the three-way
split between `essential`, `replaceable`, and `optional` ingredient roles,
and I changed my understanding of it partway through building the
feasibility rule. My first instinct was that "replaceable" could be treated
as inherently low-risk - if an ingredient is swappable, a missing one
shouldn't really block a recipe. That turns out to be wrong, and building
`RecipeEvaluation.feasibility` is what exposed why: a *replaceable*
ingredient with no substitute actually sitting in the pantry is exactly as
blocking as an *essential* one, because "replaceable in principle" and
"replaceable right now, with what's actually in this pantry" are different
claims. The role only tells you the ingredient's importance to the dish; it
says nothing about whether a rescue exists. I had to encode both facts
together before the rule stopped producing advice that quietly assumed a
substitute the cook didn't have. The test
`test_feasibility_prefersBlocked_whenBothUnresolvedAndAdjustableIngredientsExist`
exists specifically because I wanted a permanent, named check that a
recipe with one genuinely blocked ingredient can never be reported as
merely "needs adjustments," even when some other ingredient in the same
recipe *is* adjustable. The other domain choice worth naming: I kept the
MVP's deliberate refusal to convert between units (grams vs. tablespoons).
A cook can be misled by a wrong conversion far more easily than by an
honest "I don't know, here's what you have" - so
`EvaluateRecipeFeasibilityUseCase` reports a dedicated `quantityUnverified`
state rather than guessing, and leaves the raw pantry quantity visible so
the cook can judge for themselves. An earlier version of this fallback
collapsed straight to `available`, which I later corrected once I realised
it could tell a cook an ingredient was sufficient when it had never
actually been compared - exactly the kind of false certainty this whole
design choice was meant to avoid. FridgeFix's stakeholder is a private
individual, not an institution - but the engineering problem is the same:
real judgement calls encoded as testable, auditable rules with
human-facing consequences (see README, "Why This Is a Business Domain,
Not a Demo App").

## Architecture decisions

The Use Case layer exists because ViewModels are a bad place to trust with
business rules - not for abstract reasons, but because a ViewModel's job
is presentation state, and presentation state changes for UI reasons that
have nothing to do with the domain (a new screen, a different navigation
flow). Every validation rule, duplicate check, and the feasibility
calculation itself lives in a `struct` with one `execute` method and
injected dependencies, so it can be constructed and tested with no SwiftUI,
no simulator, and no ViewModel in the loop at all. The one deliberate
exception is `RecipeEvaluation.feasibility`: it's a pure computed property
on the domain model rather than a private method inside the use case,
specifically so the UI, the tests, and this documentation all read the
*same* value instead of three independently-written descriptions of the
same rule that could silently drift apart. A less pleasant architecture
lesson came from a real bug: partway through Phase 3, `PantryViewModelTests`
crashed with a libmalloc double-free, traced to the Xcode 26 template's
project-wide `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which silently
isolated *every* class in the module to the main actor - including a
plain in-memory repository that had no business being tied to it at all.
Removing that default and marking only the ViewModels explicitly
`@MainActor` fixed the crash and was the
architecturally correct call: repositories and use cases have no actor
affinity, and pretending otherwise hid a design smell behind a build
setting.

## Human-system design

The clearest human-system decision is that an error message is only
finished once the app can act on the thing it told the cook to do. The
duplicate-pantry error originally said "update the existing item instead"
- true, but the app had no edit screen, so the advice was a dead end.
Adding `UpdatePantryItemUseCase` and wiring the error directly to an edit
sheet closed that loop. The same instinct shaped `RecipeDetailView`: the
feasibility banner's guidance sentence is derived from the *same*
`RecipeEvaluation` as the ingredient list below it, on purpose, so the app
can never tell a cook "can make with adjustments" in one sentence and "no
substitute available" in the next.

## What I would do next

The most realistic next step is persistence: `PantryRepository` and
`ShoppingListRepository` are already abstracted specifically so an
`InMemoryPantryRepository` could be replaced by a SwiftData-backed one
without touching a single use case. After that, I'd want a real quantity
unit-conversion service as its own domain service (not folded into the
use case), so the "same unit only" limitation can be lifted without
compromising the honesty of the current fallback.
