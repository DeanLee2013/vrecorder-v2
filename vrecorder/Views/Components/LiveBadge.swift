//  LiveBadge.swift
//  Purpose: "同传中" capsule with a breathing aqua dot. design/README.md › LiveScreen.

import SwiftUI

struct LiveBadge: View {
    var label: String = "同传中"
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(VR.aqua500)
                .frame(width: 6, height: 6)
                .opacity(pulse ? 0.4 : 1)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            Text(label)
                .font(.system(size: VR.FontSize.caption2, weight: .bold))
                .tracking(VR.capsTracking)
                .foregroundStyle(VR.aqua500)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(VR.liveSoft))
        .onAppear { pulse = true }
    }
}
