//
//  RecipeRepository.swift
//  FridgeFix
//

import Foundation

/// Abstraction over where FridgeFix's recipes come from.
///
/// FridgeFix's current scope only needs a fixed set of locally-defined
/// sample recipes — there is no recipe authoring or import feature — but
/// depending on this protocol rather than a concrete data source keeps
/// ``RecipeViewModel`` free of that assumption.
protocol RecipeRepository: AnyObject {
    /// Every recipe FridgeFix knows about.
    func fetchAll() -> [Recipe]
}
