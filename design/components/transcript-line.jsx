// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/** One line of live interpretation. status: partial | final | history. */
function TranscriptLine({ status = "final", text, onParty = "b", style }) {
  const onViolet = onParty === "a";
  const styles = {
    partial: {
      fontSize: "var(--text-live-partial)",
      fontWeight: "var(--weight-regular)",
      color: onViolet ? "var(--party-a-text-dim)" : "var(--party-b-text-dim)",
      animation: "vr-thinking 1.4s var(--ease-breathe) infinite",
    },
    final: {
      fontSize: "var(--text-live-final)",
      fontWeight: "var(--weight-semibold)",
      color: onViolet ? "var(--party-a-text)" : "var(--party-b-text)",
    },
    history: {
      fontSize: "var(--text-live-history)",
      fontWeight: "var(--weight-regular)",
      color: onViolet ? "var(--party-a-text-dim)" : "var(--party-b-text-dim)",
    },
  };
  return (
    <p
      style={{
        margin: 0,
        maxWidth: "var(--width-readable)",
        lineHeight: "var(--leading-normal)",
        textWrap: "pretty",
        transition: "font-size var(--duration-base) var(--ease-out), color var(--duration-base) var(--ease-out)",
        ...styles[status],
        ...style,
      }}
    >
      {text}
    </p>
  );
}
