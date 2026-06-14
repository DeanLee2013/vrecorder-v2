// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/** "Live" status pill with breathing dot — shown while a session is active. */
function LiveBadge({ label = "同传中", style }) {
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 6,
        padding: "4px 10px",
        borderRadius: "var(--radius-pill)",
        background: "var(--live-soft)",
        color: "var(--text-live)",
        fontSize: "var(--text-caption2)",
        fontWeight: "var(--weight-bold)",
        letterSpacing: "var(--tracking-caps)",
        textTransform: "uppercase",
        ...style,
      }}
    >
      <span
        style={{
          width: 6,
          height: 6,
          borderRadius: "50%",
          background: "var(--live)",
          animation: "vr-pulse 1.6s var(--ease-breathe) infinite",
        }}
      ></span>
      {label}
    </span>
  );
}
