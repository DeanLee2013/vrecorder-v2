//  SettingsScreen.swift
//  Purpose: Light-scope grouped settings list. Mirrors design/settings-screen.jsx.
//  Stage-1 build keeps choices in local @State; Stage 2 backs them with
//  UserDefaults + Keychain (API key). No real persistence yet.

import SwiftUI

struct SettingsScreen: View {
    let onBack: () -> Void
    /// Reflects real Keychain state — never hardcode "已配置" (audit #2).
    var apiKeyConfigured: Bool = false

    @State private var engine = "Claude"
    @State private var stream = true
    @State private var autoSpeak = true
    @State private var speed = "1.0×"
    @State private var subSize = "标准"
    @State private var transcribeOnly = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 24) {
                    group("翻译引擎") {
                        cycleRow("翻译服务", $engine, ["Claude", "OpenAI"])
                        navRow("API 密钥", value: apiKeyConfigured ? "已配置" : "未配置")
                        toggleRow("流式翻译", $stream, last: true)
                    }
                    group("语音播报") {
                        toggleRow("自动播报译文", $autoSpeak)
                        cycleRow("语速", $speed, ["0.8×", "1.0×", "1.2×"], last: true)
                    }
                    group("同声传译") {
                        cycleRow("字幕字号", $subSize, ["标准", "大", "特大"])
                        toggleRow("仅转写模式", $transcribeOnly, last: true)
                    }
                    group("通用") {
                        navRow("历史记录", value: "保留 30 天")
                        destructiveRow("清空翻译记录")
                        navRow("关于", value: "版本 1.0.0", last: true)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .padding(.bottom, 40)
            }
        }
        .background(VR.surfaceApp)
        .ignoresSafeArea(edges: .bottom)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(VR.accentLight)
            }
            Text("设置")
                .font(.system(size: VR.FontSize.title1, weight: .bold))
                .foregroundStyle(VR.textPrimaryLight)
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 10)
    }

    // MARK: Rows

    @ViewBuilder
    private func group<C: View>(_ caption: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.system(size: VR.FontSize.caption))
                .tracking(VR.capsTracking)
                .foregroundStyle(VR.textFaint)
                .padding(.horizontal, 16)
            VStack(spacing: 0) { content() }
                .background(VR.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    private func rowChrome<T: View>(_ last: Bool, @ViewBuilder _ content: () -> T) -> some View {
        VStack(spacing: 0) {
            content().frame(minHeight: 50).padding(.horizontal, 16)
            if !last { Divider().background(VR.hairlineLight).padding(.leading, 16) }
        }
    }

    private func navRow(_ label: String, value: String, last: Bool = false) -> some View {
        rowChrome(last) {
            HStack {
                Text(label).foregroundStyle(VR.textPrimaryLight)
                Spacer()
                Text(value).foregroundStyle(VR.textFaint)
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
            }.font(.system(size: VR.FontSize.body))
        }
    }

    private func cycleRow(_ label: String, _ sel: Binding<String>, _ options: [String], last: Bool = false) -> some View {
        rowChrome(last) {
            Button {
                let i = options.firstIndex(of: sel.wrappedValue) ?? 0
                sel.wrappedValue = options[(i + 1) % options.count]
            } label: {
                HStack {
                    Text(label).foregroundStyle(VR.textPrimaryLight)
                    Spacer()
                    Text(sel.wrappedValue).foregroundStyle(VR.textFaint)
                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(VR.textFaint)
                }.font(.system(size: VR.FontSize.body))
            }.buttonStyle(.plain)
        }
    }

    private func toggleRow(_ label: String, _ on: Binding<Bool>, last: Bool = false) -> some View {
        rowChrome(last) {
            Toggle(isOn: on) {
                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.textPrimaryLight)
            }.tint(VR.violet500)
        }
    }

    private func destructiveRow(_ label: String) -> some View {
        rowChrome(false) {
            Button {} label: {
                Text(label).font(.system(size: VR.FontSize.body)).foregroundStyle(VR.red500)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.buttonStyle(.plain)
        }
    }
}
