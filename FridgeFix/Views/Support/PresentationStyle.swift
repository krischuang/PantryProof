//
//  PresentationStyle.swift
//  FridgeFix
//

import SwiftUI

// MARK: - Status colour mapping
//
// Just colour for states the domain layer already decided - no business
// logic here, which is why this lives in Views, not Domain.

extension RecipeFeasibility {
    var color: Color {
        switch self {
        case .readyToCook: return .green
        case .canMakeWithAdjustments: return .orange
        case .blocked: return .red
        }
    }
}

extension IngredientAvailability {
    var color: Color {
        switch self {
        case .available: return .green
        case .insufficient: return .orange
        case .missing: return .red
        case .quantityUnverified: return .blue
        }
    }
}

extension IngredientRole {
    /// Different palette from ``IngredientAvailability/color`` on purpose,
    /// so the role badge doesn't get confused with the availability icon
    /// next to it.
    var tint: Color {
        switch self {
        case .essential: return .purple
        case .replaceable: return .teal
        case .optional: return .secondary
        }
    }
}

extension IngredientCategory {
    /// Just for giving pantry rows a recognisable colour - not used for
    /// feasibility or availability.
    var tint: Color {
        switch self {
        case .produce: return .green
        case .dairy: return .blue
        case .meat: return .red
        case .grain: return .brown
        case .spice: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Small reusable components
//
// Shared pieces used across Pantry, Recipe and Shopping List screens so
// badges/icons/errors look the same everywhere.

/// A small icon in a tinted circle - used for category icons and similar.
struct IconBadge: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }
}

/// A small icon + label pill for role/status tags like "Essential".
struct TagBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// An inline error message with an icon and tinted background - used
/// instead of plain red text wherever a form needs to show an error.
struct InlineErrorBanner: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
                .font(.callout)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.red)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
