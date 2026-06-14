// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/** Circular microphone button. States: idle | listening | disabled. */
function MicButton({ state = "idle", size = 72, onClick, label = "开始说话", style }) {
  const listening = state === "listening";
  const disabled = state === "disabled";
  return (
    <button
      aria-label={label}
      aria-pressed={listening}
      disabled={disabled}
      onClick={onClick}
      style={{
        width: size,
        height: size,
        border: "none",
        borderRadius: "50%",
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: disabled ? "default" : "pointer",
        background: listening ? "var(--live)" : "var(--accent)",
        color: listening ? "var(--ink-950)" : "var(--text-on-accent)",
        boxShadow: listening ? "var(--glow-live)" : "var(--shadow-pop)",
        opacity: disabled ? 0.4 : 1,
        animation: listening ? "vr-pulse 1.6s var(--ease-breathe) infinite" : "none",
        transition: "background var(--duration-base) var(--ease-out), box-shadow var(--duration-base) var(--ease-out)",
        ...style,
      }}
    >
      <svg width={size * 0.36} height={size * 0.36} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"></path>
        <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
        <line x1="12" x2="12" y1="19" y2="22"></line>
      </svg>
    </button>
  );
}
