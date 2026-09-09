//
//  RecipeIngredient.swift
//  FridgeFix
//

import Foundation

/// How important an ingredient is to a recipe - the main input to the
/// feasibility rules.
///
/// Running out of chicken in a chicken curry isn't the same problem as
/// running out of a garnish, so each role gets a different rule:
///
/// - ``essential``: central to the dish. Missing/insufficient blocks the
///   recipe unless there's a substitute.
/// - ``replaceable``: changes the dish but isn't the star. Same rule as
///   essential - no substitute means it's just as blocking.
/// - ``optional``: garnish/extra. Never blocks the recipe.
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

/// An ``Ingredient`` as required by one recipe: how much, what unit, and
/// how important it is to the dish.
///
/// Role and quantity live here instead of on `Ingredient` because the same
/// ingredient (e.g. milk) can be essential in one recipe and optional in
/// another.
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
