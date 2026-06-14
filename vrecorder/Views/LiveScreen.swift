//  LiveScreen.swift
//  Purpose: Main screen — full-screen two-party split (ink top / violet bottom).
//  Mirrors design/live-screen.jsx. Stage-1 build is driven by LiveSessionModel's
//  demo simulator; the real pipeline plugs into the same model in Stage 2.

import SwiftUI

struct LiveScreen: View {
    @State private var session: LiveSessionModel
    let onSettings: () -> Void

    init(session: LiveSessionModel, onSettings: @escaping () -> Void) {
        _session = State(initialValue: session)
        self.onSettings = onSettings
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                partyB
                partyA
            }
        }
        .background(VR.partyBSurface)
        .ignoresSafeArea()
        .alert("同传出错", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.clearError() } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(session.errorMessage ?? "")
        }
    }

    // MARK: Counterpart (ink, English)

    private var partyB: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("ENGLISH")
                    .font(.system(size: VR.FontSize.caption))
                    .tracking(VR.capsTracking)
                    .foregroundStyle(VR.partyBTextDim)
                ForEach(session.partyB) { TranscriptLineView(line: $0, party: .b) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            topBar
                .padding(.horizontal, 12)
                .padding(.top, 54)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBar: some View {
        HStack {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(VR.partyBTextDim)
                    .frame(width: 40, height: 40)
            }
            .accessibilityIdentifier("vr.live.gear")
            Spacer()
            LiveBadge().opacity(session.listening ? 1 : 0)
            Spacer()
            Button {} label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 20))
                    .foregroundStyle(VR.partyBTextDim)
                    .frame(width: 40, height: 40)
            }
        }
    }

    // MARK: You (violet "water", 中文)

    private var partyA: some View {
        ZStack(alignment: .top) {
            VR.partyASurface
            WaterSurface(listening: session.listening)
                .offset(y: -44)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 8) {
                Text("中文 · 普通话")
                    .font(.system(size: VR.FontSize.caption))
                    .tracking(VR.capsTracking)
                    .foregroundStyle(VR.partyATextDim)
                if session.showPrompt {
                    Text("请开始说话吧")
                        .font(.system(size: VR.FontSize.partial))
                        .foregroundStyle(VR.partyATextDim)
                }
                ForEach(session.partyA) { TranscriptLineView(line: $0, party: .a) }

                Spacer()
                VStack(spacing: 10) {
                    MicButton(listening: session.listening) { session.toggle() }
                        .accessibilityIdentifier("vr.live.mic")
                        .accessibilityValue(session.listening ? "listening" : "idle")
                    Text("为保证同传效果，请靠近麦克风说话")
                        .font(.system(size: VR.FontSize.caption))
                        .foregroundStyle(VR.partyATextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}
