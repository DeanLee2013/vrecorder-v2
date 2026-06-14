//  WaterSurface.swift
//  Purpose: The violet panel's top edge rendered as "water". Idle = near-flat
//  line; listening = three drifting sine layers (opacity 0.35/0.55/1.0).
//  TimelineView(.animation) + Canvas per design/README.md › WaterSurface.

import SwiftUI

struct WaterSurface: View {
    let listening: Bool
    var fill: Color = VR.partyASurface
    var height: CGFloat = 44

    var body: some View {
        TimelineView(.animation(paused: !listening)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let energy = listening ? 0.7 + 0.3 * sin(t * 0.9) : 0.04
                let layers: [(amp: Double, freq: Double, phase: Double, opacity: Double)] = [
                    (0.35, 1.4, t * 0.6, 0.35),
                    (0.45, 1.7, -t * 0.8 + 1.0, 0.55),
                    (0.55, 1.9, t * 1.1 + 2.0, 1.0),
                ]
                for layer in layers {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: size.height))
                    let baseY = size.height * (1 - energy * layer.amp)
                    for x in stride(from: 0.0, through: size.width, by: 2) {
                        let phase = (x / size.width) * layer.freq * 2 * .pi + layer.phase
                        let wave = sin(phase) + 0.3 * sin(phase * 2.3)
                        let y = baseY + wave * size.height * 0.18 * energy
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(fill.opacity(layer.opacity)))
                }
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
