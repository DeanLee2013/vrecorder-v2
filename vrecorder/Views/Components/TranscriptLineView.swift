//  TranscriptLineView.swift
//  Purpose: Render one TranscriptLine with size/weight/opacity per status, and
//  animate the partial → final promotion (250ms ease-out). design/README.md.

import SwiftUI

struct TranscriptLineView: View {
    let line: TranscriptLine
    /// "a" = violet (you), "b" = ink (counterpart) — drives the text color.
    let party: Party

    enum Party { case a, b }

    var body: some View {
        Text(line.text)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.25), value: line.status)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var size: CGFloat {
        switch line.status {
        case .partial: VR.FontSize.partial
        case .final:   VR.FontSize.final
        case .history: VR.FontSize.history
        }
    }

    private var weight: Font.Weight {
        line.status == .final ? .semibold : .regular
    }

    private var opacity: Double {
        line.status == .partial ? 0.62 : 1.0
    }

    private var color: Color {
        let dim = line.status == .history
        switch party {
        case .a: return dim ? VR.partyATextDim : VR.partyAText
        case .b: return dim ? VR.partyBTextDim : VR.partyBText
        }
    }
}
