//  MicButton.swift
//  Purpose: 64pt circular mic control. Idle = violet; listening = aqua with
//  glow + breathing pulse. design/README.md › LiveScreen. No spring overshoot.

import SwiftUI

struct MicButton: View {
    let listening: Bool
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(listening ? VR.aqua500 : VR.violet500)
                Image(systemName: "mic.fill")
                    .font(.system(size: 64 * 0.36, weight: .regular))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .scaleEffect(listening && pulse ? 1.08 : 1.0)
            .shadow(color: listening ? VR.aqua500.opacity(0.30) : .black.opacity(0.25),
                    radius: listening ? 14 : 8, y: listening ? 0 : 4)
            .overlay(
                Circle().stroke(VR.aqua500.opacity(listening ? 0.16 : 0), lineWidth: 6)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        .onChange(of: listening) { _, on in pulse = on }
    }
}
