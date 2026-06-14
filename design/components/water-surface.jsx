// Reference copy for iOS handoff — not part of the design-system bundle.
import React from "react";

/* Water-surface boundary (腾讯翻译君-style): the panel below is "water in a
   glass"; this renders its rippling top edge as filled wave layers. Place it
   flush above the colored panel — fill must match the panel background. */
const SURFACE_LAYERS = [
  { cycles: 1.9, speed: 2.2, amp: 0.55, phase: 2.1, opacity: 0.35, lift: 0.55 },
  { cycles: 1.4, speed: -1.7, amp: 0.75, phase: 0.6, opacity: 0.55, lift: 0.3 },
  { cycles: 1.6, speed: 2.9, amp: 1.0, phase: 0, opacity: 1, lift: 0 },
];

/** Rippling water-surface top edge for a filled panel. States: idle | listening | speaking. */
function WaterSurface({
  state = "idle",
  fill = "var(--party-a-surface)",
  height = 44,
  style,
}) {
  const W = 400; // viewBox width; SVG stretches to 100%
  const H = height;
  const refs = React.useRef([]);
  const stateAmp = state === "listening" ? 1 : state === "speaking" ? 0.55 : 0;

  const pathFor = React.useCallback((layer, t) => {
    /* waterline sits low; ripples rise from it */
    const base = H - 10 - layer.lift * 8;
    const maxA = (H - 14) * 0.5 * stateAmp * layer.amp;
    const energy = 0.7 + 0.3 * Math.sin(t * 1.1 + layer.phase) * Math.sin(t * 0.63 + 1.7);
    const N = 56;
    let d = "M0 " + (H + 2) + " ";
    for (let i = 0; i <= N; i++) {
      const u = i / N;
      const y = base - Math.max(0, maxA * energy * (
        Math.sin(2 * Math.PI * layer.cycles * u + layer.phase + t * layer.speed) * 0.7 +
        Math.sin(2 * Math.PI * (layer.cycles * 2.3) * u - t * layer.speed * 0.6) * 0.3 + 0.35
      ));
      d += "L" + (u * W).toFixed(1) + " " + y.toFixed(2) + " ";
    }
    return d + "L" + W + " " + (H + 2) + " Z";
  }, [H, stateAmp]);

  React.useEffect(() => {
    refs.current.forEach((el, i) => el && el.setAttribute("d", pathFor(SURFACE_LAYERS[i], 0.5)));
    if (state === "idle") return undefined;
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return undefined;
    }
    let raf;
    const start = performance.now();
    const loop = (now) => {
      const t = 0.5 + (now - start) / 1000;
      refs.current.forEach((el, i) => el && el.setAttribute("d", pathFor(SURFACE_LAYERS[i], t)));
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [state, pathFor]);

  return (
    <svg
      width="100%"
      height={H}
      viewBox={"0 0 " + W + " " + H}
      preserveAspectRatio="none"
      aria-hidden="true"
      style={{ display: "block", ...style }}
    >
      {SURFACE_LAYERS.map((layer, i) => (
        <path
          key={i}
          ref={(el) => { refs.current[i] = el; }}
          d={pathFor(layer, 0.5)}
          fill={fill}
          opacity={layer.opacity}
        ></path>
      ))}
    </svg>
  );
}
