//  Palette.swift
//  Purpose: Single source of truth for VRecorder color tokens, mirrored from
//  design/tokens/colors.css. UI code references these names, never raw hex.

import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// VRecorder design tokens. Names follow design/tokens/colors.css.
enum VR {
    // Ink scale
    static let ink950 = Color(hex: 0x07070C)
    static let ink900 = Color(hex: 0x0C0C14)
    static let ink800 = Color(hex: 0x14141F)
    static let ink400 = Color(hex: 0x6B6B85)
    static let ink300 = Color(hex: 0x9494AE)
    static let ink100 = Color(hex: 0xE9E9F2)
    static let ink50  = Color(hex: 0xF7F7FB)

    // Violet (brand / speech energy)
    static let violet600 = Color(hex: 0x5B3DF5)
    static let violet500 = Color(hex: 0x7050FF)
    static let violet400 = Color(hex: 0x8F76FF)

    // Aqua (listening / live)
    static let aqua500 = Color(hex: 0x2BD9C8)

    // Status
    static let red500 = Color(hex: 0xFF5C5C)

    // Two-party split
    static let partyASurface = violet600
    static let partyAText = Color.white
    static let partyATextDim = Color.white.opacity(0.62)
    static let partyBSurface = ink950
    static let partyBText = ink100
    static let partyBTextDim = ink400

    // Live badge / mic glow
    static let liveSoft = Color(hex: 0x2BD9C8, opacity: 0.14)

    // Light-scope (settings)
    static let surfaceApp = ink50
    static let surfaceCard = Color.white
    static let textPrimaryLight = ink900
    static let textFaint = ink400
    static let hairlineLight = Color(hex: 0x0C0C14, opacity: 0.08)
    static let accentLight = violet600
}
