// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/** iOS-style switch. Controlled. */
function Switch({ checked = false, onChange, disabled = false, label, style }) {
  return (
    <button
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange && onChange(!checked)}
      style={{
        width: 51,
        height: 31,
        padding: 2,
        border: "none",
        borderRadius: "var(--radius-pill)",
        background: checked ? "var(--accent)" : "var(--ink-600)",
        cursor: disabled ? "default" : "pointer",
        opacity: disabled ? 0.4 : 1,
        transition: "background var(--duration-base) var(--ease-out)",
        display: "inline-block",
        ...style,
      }}
    >
      <span
        style={{
          display: "block",
          width: 27,
          height: 27,
          borderRadius: "50%",
          background: "#FFFFFF",
          boxShadow: "0 1px 3px rgba(0,0,0,0.3)",
          transform: checked ? "translateX(20px)" : "translateX(0)",
          transition: "transform var(--duration-base) var(--ease-out)",
        }}
      ></span>
    </button>
  );
}
