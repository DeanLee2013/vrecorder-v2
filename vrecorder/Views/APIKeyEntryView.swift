//  APIKeyEntryView.swift
//  Purpose: Light-scope sheet to enter / clear the OpenAI API key (feature #2).
//  Built from VR design tokens per dev-docs/designs/api-key-entry/. Owns exactly
//  one APIKeyEntryModel via @State (constructed from the injected store). The
//  model is the single source of truth; the view never touches the store directly.

import SwiftUI

struct APIKeyEntryView: View {
    @State private var model: APIKeyEntryModel
    @State private var confirmClear = false
    let onClose: () -> Void

    init(store: any APIKeyStoring, onClose: @escaping () -> Void) {
        _model = State(initialValue: APIKeyEntryModel(store: store))
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OPENAI")
                        .font(.system(size: VR.FontSize.caption)).tracking(VR.capsTracking)
                        .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
                    keyCard
                    if let err = model.errorMessage {
                        Text(err).font(.system(size: VR.FontSize.caption))
                            .foregroundStyle(VR.red500).padding(.horizontal, 16)
                    } else if let masked = model.maskedExisting {
                        Text("当前：\(masked)").font(.system(size: VR.FontSize.caption))
                            .foregroundStyle(VR.textFaint).padding(.horizontal, 16)
                    }
                    if model.hasExistingKey { clearCard }
                    notice
                }
                .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 40)
            }
        }
        .background(VR.surfaceApp)
        .alert("清除密钥？", isPresented: $confirmClear) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) { _ = model.clear() }
        } message: { Text("清除后需重新输入才能继续同传。") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("取消", action: onClose).foregroundStyle(VR.textFaint)
                Spacer()
                Button("保存") { if model.save() { onClose() } }
                    .font(.system(size: VR.FontSize.body, weight: .semibold))
                    .foregroundStyle(model.canSave ? VR.accentLight : VR.textFaint)
                    .disabled(!model.canSave)
                    .accessibilityIdentifier("vr.apikey.save")
            }
            .font(.system(size: VR.FontSize.body))
            .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 6)
            Text("API 密钥")
                .font(.system(size: VR.FontSize.title1, weight: .bold))
                .foregroundStyle(VR.textPrimaryLight)
                .padding(.horizontal, 20).padding(.bottom, 18)
        }
    }

    private var keyCard: some View {
        HStack(spacing: 12) {
            Text("密钥").foregroundStyle(VR.textFaint)
            SecureField("sk-…", text: $model.draft)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .foregroundStyle(VR.textPrimaryLight)
                .accessibilityIdentifier("vr.apikey.field")
        }
        .font(.system(size: VR.FontSize.body))
        .frame(minHeight: 50).padding(.horizontal, 16)
        .background(VR.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var clearCard: some View {
        Button { confirmClear = true } label: {
            Text("清除密钥").foregroundStyle(VR.red500)
                .font(.system(size: VR.FontSize.body))
                .accessibilityIdentifier("vr.apikey.clear")
                .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .background(VR.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.top, 16)
    }

    private var notice: some View {
        Text("你的密钥保存在本机钥匙串（Keychain）。同传时会以 Bearer 凭证经 TLS 发送给你选择的服务商（OpenAI），不会发给其它第三方。设备被攻破时密钥仍可能泄露。")
            .font(.system(size: VR.FontSize.caption))
            .foregroundStyle(VR.textFaint)
            .padding(.horizontal, 16).padding(.top, 28)
    }
}
