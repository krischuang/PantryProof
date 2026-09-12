//
//  RecipeRepository.swift
//  PantryProof
//

import Foundation

/// Abstraction over where recipes come from.
///
/// Right now it's just a fixed list of sample recipes, but
/// ``RecipeViewModel`` doesn't need to know that.
protocol RecipeRepository: AnyObject {
    /// Every recipe PantryProof knows about.
    func fetchAll() -> [Recipe]
}
