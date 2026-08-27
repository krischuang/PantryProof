//
//  RecipeIngredient.swift
//  FridgeFix
//

import Foundation

/// The importance a recipe assigns to one of its ingredients, and the
/// central input to FridgeFix's feasibility rules.
///
/// A recipe cannot treat every missing ingredient the same way: running
/// out of chicken in a chicken curry is not the same situation as running
/// out of a garnish. `IngredientRole` makes that distinction explicit so
/// ``EvaluateRecipeFeasibilityUseCase`` can apply a different rule to each:
///
/// - ``essential``: central to the dish. Missing or insufficient blocks
///   the recipe unless a substitute is available.
/// - ``replaceable``: not central, but still meaningfully changes the
///   dish. Missing or insufficient blocks the recipe *unless* a substitute
///   is available — a replaceable ingredient the cook can neither buy nor
///   swap out is exactly as blocking as an essential one.
/// - ``optional``: a garnish or enhancement. Missing or insufficient never
///   blocks the recipe.
enum IngredientRole: String, Codable, CaseIterable {
    case essential
    case replaceable
    case optional

    var displayName: String {
        switch self {
        case .essential: return "Essential"
        case .replaceable: return "Replaceable"
        case .optional: return "Optional"
        }
    }

    var symbolName: String {
        switch self {
        case .essential: return "exclamationmark.triangle.fill"
        case .replaceable: return "arrow.triangle.2.circlepath"
        case .optional: return "circle"
        }
    }
}

/// An ``Ingredient`` as required by one specific ``Recipe``: how much of it
/// is needed, in what unit, and how important it is to the dish.
///
/// The same `Ingredient` (e.g. "Milk") can be essential in one recipe and
/// merely optional in another, which is why role and quantity live here,
/// on the recipe's own requirement, rather than on `Ingredient` itself.
struct RecipeIngredient: Identifiable, Hashable, Codable {
    let id: UUID
    var ingredient: Ingredient
    var quantity: Double
    var unit: MeasurementUnit
    var role: IngredientRole

    init(id: UUID = UUID(), ingredient: Ingredient, quantity: Double, unit: MeasurementUnit, role: IngredientRole) {
        self.id = id
        self.ingredient = ingredient
        self.quantity = quantity
        self.unit = unit
        self.role = role
    }

    var formattedQuantity: String { unit.formatted(quantity) }
}
