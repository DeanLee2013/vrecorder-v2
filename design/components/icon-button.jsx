// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/** Circular icon-only button. Variants: tonal | ghost | filled | outline. */
function IconButton({
  variant = "tonal",
  size = 44,
  disabled = false,
  label,
  children,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const variants = {
    tonal: { background: "var(--surface-raised)", color: "var(--text-primary)" },
    ghost: { background: "transparent", color: "var(--text-secondary)" },
    filled: { background: "var(--accent)", color: "var(--text-on-accent)" },
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      boxShadow: "inset 0 0 0 1px var(--hairline-strong)",
    },
  };
  return (
    <button
      aria-label={label}
      disabled={disabled}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        width: size,
        height: size,
        border: "none",
        borderRadius: "var(--radius-pill)",
        cursor: disabled ? "default" : "pointer",
        opacity: disabled ? 0.4 : 1,
        transform: pressed && !disabled ? "scale(0.94)" : "scale(1)",
        transition: "transform var(--duration-fast) var(--ease-out)",
        ...variants[variant],
        ...style,
      }}
      {...rest}
    >
      {children}
    </button>
  );
}
