//  Typography.swift
//  Purpose: Font-size tokens from design/README.md (SF Pro + PingFang SC).
//  Subtitle-specific sizes drive the partial → final → history transition.

import SwiftUI

extension VR {
    enum FontSize {
        static let caption2: CGFloat = 11
        static let caption: CGFloat = 13
        static let body: CGFloat = 17
        static let title1: CGFloat = 28

        // Subtitle (live transcript) states
        static let partial: CGFloat = 22
        static let final: CGFloat = 30
        static let history: CGFloat = 17
    }

    /// Letter-spacing used for all-caps language labels / live badge.
    static let capsTracking: CGFloat = 0.06 * 13
}
