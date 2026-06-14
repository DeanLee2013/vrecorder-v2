/* @ds-bundle: {"format":3,"namespace":"VRecorderDesignSystem_e7fff0","components":[{"name":"HoldToTalkBar","sourcePath":"components/conversation/HoldToTalkBar.jsx"},{"name":"LiveBadge","sourcePath":"components/conversation/LiveBadge.jsx"},{"name":"MessageBubble","sourcePath":"components/conversation/MessageBubble.jsx"},{"name":"MicButton","sourcePath":"components/conversation/MicButton.jsx"},{"name":"TranscriptLine","sourcePath":"components/conversation/TranscriptLine.jsx"},{"name":"WaterSurface","sourcePath":"components/conversation/WaterSurface.jsx"},{"name":"Waveform","sourcePath":"components/conversation/Waveform.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"LanguageChip","sourcePath":"components/core/LanguageChip.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"Switch","sourcePath":"components/core/Switch.jsx"}],"sourceHashes":{"components/conversation/HoldToTalkBar.jsx":"395b4cdba98a","components/conversation/LiveBadge.jsx":"fd88f02c4dfe","components/conversation/MessageBubble.jsx":"ba77210e02eb","components/conversation/MicButton.jsx":"100a99f58aad","components/conversation/TranscriptLine.jsx":"fb1ce75d6a87","components/conversation/WaterSurface.jsx":"55fbf10ed463","components/conversation/Waveform.jsx":"a51e8a8bbf5d","components/core/Button.jsx":"dc5396bd0d70","components/core/Card.jsx":"f1323b1a82b3","components/core/IconButton.jsx":"2163a6e492b0","components/core/LanguageChip.jsx":"42dc34479430","components/core/SegmentedControl.jsx":"95b2176e11d6","components/core/Switch.jsx":"749f665258b4","ui_kits/app/ConversationScreen.jsx":"b96817640ba2","ui_kits/app/LanguageSheet.jsx":"926f693895b1","ui_kits/app/LiveScreen.jsx":"480b20181700","ui_kits/app/SettingsScreen.jsx":"8e85b32ca16f","ui_kits/app/TranslateScreen.jsx":"8710e7a8b0de"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.VRecorderDesignSystem_e7fff0 = window.VRecorderDesignSystem_e7fff0 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/conversation/HoldToTalkBar.jsx
try { (() => {
const micGlyph = /*#__PURE__*/React.createElement("svg", {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"
}), /*#__PURE__*/React.createElement("path", {
  d: "M19 10v2a7 7 0 0 1-14 0v-2"
}), /*#__PURE__*/React.createElement("line", {
  x1: "12",
  x2: "12",
  y1: "19",
  y2: "22"
}));

/** Two-language hold-to-talk bar. `pressedSide`: null | "a" | "b". */
function HoldToTalkBar({
  sideA = "按住说中文",
  sideB = "English",
  pressedSide = null,
  onPressStart,
  onPressEnd,
  style
}) {
  const pill = (key, text) => {
    const pressed = pressedSide === key;
    return /*#__PURE__*/React.createElement("button", {
      onPointerDown: () => onPressStart && onPressStart(key),
      onPointerUp: () => onPressEnd && onPressEnd(key),
      onPointerLeave: () => pressed && onPressEnd && onPressEnd(key),
      style: {
        flex: 1,
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        height: "var(--height-control-lg)",
        border: "none",
        fontFamily: "inherit",
        fontSize: "var(--text-body)",
        fontWeight: "var(--weight-semibold)",
        cursor: "pointer",
        background: pressed ? "var(--accent)" : "transparent",
        color: pressed ? "var(--text-on-accent)" : "var(--text-primary)",
        transition: "background var(--duration-fast) var(--ease-out), color var(--duration-fast) var(--ease-out)"
      }
    }, micGlyph, text);
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "stretch",
      background: "var(--surface-card)",
      borderRadius: "var(--radius-pill)",
      overflow: "hidden",
      boxShadow: pressedSide ? "var(--glow-accent)" : "var(--shadow-card)",
      transition: "box-shadow var(--duration-base) var(--ease-out)",
      ...style
    }
  }, pill("a", sideA), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 1,
      background: "var(--hairline)",
      margin: "10px 0"
    }
  }), pill("b", sideB));
}
Object.assign(__ds_scope, { HoldToTalkBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/HoldToTalkBar.jsx", error: String((e && e.message) || e) }); }

// components/conversation/LiveBadge.jsx
try { (() => {
/** "Live" status pill with breathing dot — shown while a session is active. */
function LiveBadge({
  label = "同传中",
  style
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
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
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: "50%",
      background: "var(--live)",
      animation: "vr-pulse 1.6s var(--ease-breathe) infinite"
    }
  }), label);
}
Object.assign(__ds_scope, { LiveBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/LiveBadge.jsx", error: String((e && e.message) || e) }); }

// components/conversation/MessageBubble.jsx
try { (() => {
const speakGlyph = /*#__PURE__*/React.createElement("svg", {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M4 9.5h2.2L10 6v12l-3.8-3.5H4z",
  fill: "currentColor",
  stroke: "none"
}), /*#__PURE__*/React.createElement("path", {
  d: "M14 8.5a5 5 0 0 1 0 7"
}), /*#__PURE__*/React.createElement("path", {
  d: "M17 6a9 9 0 0 1 0 12"
}));
const playGlyph = /*#__PURE__*/React.createElement("svg", {
  width: "14",
  height: "14",
  viewBox: "0 0 24 24",
  fill: "currentColor",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M7 4.5v15l13-7.5z"
}));

/** Conversation bubble: source line + translated line, or a voice note. */
function MessageBubble({
  role = "them",
  source,
  translation,
  voice = null,
  onSpeak,
  onPlay,
  style
}) {
  const mine = role === "me";
  const base = {
    maxWidth: 420,
    padding: "12px 16px",
    borderRadius: "var(--radius-card)",
    background: mine ? "var(--accent-soft)" : "var(--surface-card)",
    alignSelf: mine ? "flex-end" : "flex-start",
    display: "flex",
    flexDirection: "column",
    gap: 6,
    ...style
  };
  if (voice) {
    return /*#__PURE__*/React.createElement("div", {
      style: base
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: "var(--text-caption)",
        color: "var(--text-faint)"
      }
    }, voice.when), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: "var(--text-caption)",
        color: "var(--text-secondary)"
      }
    }, voice.duration), /*#__PURE__*/React.createElement("button", {
      onClick: onPlay,
      "aria-label": "\u64AD\u653E\u8BED\u97F3",
      style: {
        marginLeft: "auto",
        border: "none",
        width: 28,
        height: 28,
        borderRadius: "50%",
        background: "var(--accent)",
        color: "var(--text-on-accent)",
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "pointer"
      }
    }, playGlyph)), source ? /*#__PURE__*/React.createElement("p", {
      style: {
        margin: 0,
        fontSize: "var(--text-body)",
        color: "var(--text-primary)"
      }
    }, source) : null);
  }
  return /*#__PURE__*/React.createElement("div", {
    style: base
  }, source ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      fontSize: "var(--text-subhead)",
      color: "var(--text-secondary)"
    }
  }, source) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "flex-end",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      fontSize: "var(--text-body)",
      fontWeight: "var(--weight-semibold)",
      color: "var(--text-primary)"
    }
  }, translation), /*#__PURE__*/React.createElement("button", {
    onClick: onSpeak,
    "aria-label": "\u6717\u8BFB\u8BD1\u6587",
    style: {
      border: "none",
      background: "none",
      padding: 2,
      color: "var(--text-faint)",
      cursor: "pointer",
      flexShrink: 0
    }
  }, speakGlyph)));
}
Object.assign(__ds_scope, { MessageBubble });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/MessageBubble.jsx", error: String((e && e.message) || e) }); }

// components/conversation/MicButton.jsx
try { (() => {
/** Circular microphone button. States: idle | listening | disabled. */
function MicButton({
  state = "idle",
  size = 72,
  onClick,
  label = "开始说话",
  style
}) {
  const listening = state === "listening";
  const disabled = state === "disabled";
  return /*#__PURE__*/React.createElement("button", {
    "aria-label": label,
    "aria-pressed": listening,
    disabled: disabled,
    onClick: onClick,
    style: {
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
      ...style
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: size * 0.36,
    height: size * 0.36,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M19 10v2a7 7 0 0 1-14 0v-2"
  }), /*#__PURE__*/React.createElement("line", {
    x1: "12",
    x2: "12",
    y1: "19",
    y2: "22"
  })));
}
Object.assign(__ds_scope, { MicButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/MicButton.jsx", error: String((e && e.message) || e) }); }

// components/conversation/TranscriptLine.jsx
try { (() => {
/** One line of live interpretation. status: partial | final | history. */
function TranscriptLine({
  status = "final",
  text,
  onParty = "b",
  style
}) {
  const onViolet = onParty === "a";
  const styles = {
    partial: {
      fontSize: "var(--text-live-partial)",
      fontWeight: "var(--weight-regular)",
      color: onViolet ? "var(--party-a-text-dim)" : "var(--party-b-text-dim)",
      animation: "vr-thinking 1.4s var(--ease-breathe) infinite"
    },
    final: {
      fontSize: "var(--text-live-final)",
      fontWeight: "var(--weight-semibold)",
      color: onViolet ? "var(--party-a-text)" : "var(--party-b-text)"
    },
    history: {
      fontSize: "var(--text-live-history)",
      fontWeight: "var(--weight-regular)",
      color: onViolet ? "var(--party-a-text-dim)" : "var(--party-b-text-dim)"
    }
  };
  return /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      maxWidth: "var(--width-readable)",
      lineHeight: "var(--leading-normal)",
      textWrap: "pretty",
      transition: "font-size var(--duration-base) var(--ease-out), color var(--duration-base) var(--ease-out)",
      ...styles[status],
      ...style
    }
  }, text);
}
Object.assign(__ds_scope, { TranscriptLine });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/TranscriptLine.jsx", error: String((e && e.message) || e) }); }

// components/conversation/WaterSurface.jsx
try { (() => {
/* Water-surface boundary (腾讯翻译君-style): the panel below is "water in a
   glass"; this renders its rippling top edge as filled wave layers. Place it
   flush above the colored panel — fill must match the panel background. */
const SURFACE_LAYERS = [{
  cycles: 1.9,
  speed: 2.2,
  amp: 0.55,
  phase: 2.1,
  opacity: 0.35,
  lift: 0.55
}, {
  cycles: 1.4,
  speed: -1.7,
  amp: 0.75,
  phase: 0.6,
  opacity: 0.55,
  lift: 0.3
}, {
  cycles: 1.6,
  speed: 2.9,
  amp: 1.0,
  phase: 0,
  opacity: 1,
  lift: 0
}];

/** Rippling water-surface top edge for a filled panel. States: idle | listening | speaking. */
function WaterSurface({
  state = "idle",
  fill = "var(--party-a-surface)",
  height = 44,
  style
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
      const y = base - Math.max(0, maxA * energy * (Math.sin(2 * Math.PI * layer.cycles * u + layer.phase + t * layer.speed) * 0.7 + Math.sin(2 * Math.PI * (layer.cycles * 2.3) * u - t * layer.speed * 0.6) * 0.3 + 0.35));
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
    const loop = now => {
      const t = 0.5 + (now - start) / 1000;
      refs.current.forEach((el, i) => el && el.setAttribute("d", pathFor(SURFACE_LAYERS[i], t)));
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [state, pathFor]);
  return /*#__PURE__*/React.createElement("svg", {
    width: "100%",
    height: H,
    viewBox: "0 0 " + W + " " + H,
    preserveAspectRatio: "none",
    "aria-hidden": "true",
    style: {
      display: "block",
      ...style
    }
  }, SURFACE_LAYERS.map((layer, i) => /*#__PURE__*/React.createElement("path", {
    key: i,
    ref: el => {
      refs.current[i] = el;
    },
    d: pathFor(layer, 0.5),
    fill: fill,
    opacity: layer.opacity
  })));
}
Object.assign(__ds_scope, { WaterSurface });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/WaterSurface.jsx", error: String((e && e.message) || e) }); }

// components/conversation/Waveform.jsx
try { (() => {
/* Layered flowing sine curves (翻译君 / Siri-style). Each layer differs in
   frequency, drift speed and opacity; amplitudes breathe with a slow energy
   envelope so the wave feels like live speech, not a metronome. */
const WAVE_LAYERS = [{
  cycles: 1.7,
  speed: 2.6,
  amp: 1.0,
  opacity: 0.95,
  strokeWidth: 2.5,
  phase: 0
}, {
  cycles: 2.4,
  speed: -3.4,
  amp: 0.62,
  opacity: 0.4,
  strokeWidth: 2,
  phase: 1.4
}, {
  cycles: 3.2,
  speed: 4.6,
  amp: 0.38,
  opacity: 0.2,
  strokeWidth: 1.5,
  phase: 2.8
}];

/** Smooth flowing voice wave. States: idle | listening | speaking. */
function Waveform({
  state = "idle",
  color = "var(--accent)",
  bars = 24,
  // legacy width hint: width defaults to bars * 6
  width,
  height = 36,
  style
}) {
  const W = width || bars * 6;
  const H = height;
  const refs = React.useRef([]);
  const stateAmp = state === "listening" ? 1 : state === "speaking" ? 0.6 : 0.06;
  const pathFor = React.useCallback((layer, t) => {
    const half = H / 2;
    const maxA = Math.max(half - 2, 1) * stateAmp * layer.amp;
    /* slow, irregular energy so peaks rise and fall like real speech */
    const energy = 0.7 + 0.3 * Math.sin(t * 1.3 + layer.phase) * Math.sin(t * 0.71 + 2);
    const N = 64;
    let d = "";
    for (let i = 0; i <= N; i++) {
      const u = i / N;
      const env = Math.pow(Math.sin(Math.PI * u), 1.15); // big center, pinched ends
      const y = half + maxA * energy * env * Math.sin(2 * Math.PI * layer.cycles * u + layer.phase + t * layer.speed);
      d += (i === 0 ? "M" : "L") + (u * W).toFixed(1) + " " + y.toFixed(2) + " ";
    }
    return d;
  }, [W, H, stateAmp]);
  React.useEffect(() => {
    refs.current.forEach((el, i) => el && el.setAttribute("d", pathFor(WAVE_LAYERS[i], 0.8)));
    if (state === "idle") return undefined;
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return undefined; // static mid-energy frame already drawn above
    }
    let raf;
    const start = performance.now();
    const loop = now => {
      const t = 0.8 + (now - start) / 1000;
      refs.current.forEach((el, i) => el && el.setAttribute("d", pathFor(WAVE_LAYERS[i], t)));
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [state, pathFor]);
  return /*#__PURE__*/React.createElement("svg", {
    width: W,
    height: H,
    viewBox: "0 0 " + W + " " + H,
    "aria-hidden": "true",
    style: {
      display: "block",
      overflow: "visible",
      opacity: state === "idle" ? 0.45 : 1,
      filter: state === "listening" ? "drop-shadow(0 0 8px " + color + ")" : "none",
      transition: "opacity var(--duration-base) var(--ease-out)",
      ...style
    }
  }, WAVE_LAYERS.map((layer, i) => /*#__PURE__*/React.createElement("path", {
    key: i,
    ref: el => {
      refs.current[i] = el;
    },
    d: pathFor(layer, 0.8),
    fill: "none",
    stroke: color,
    strokeWidth: layer.strokeWidth,
    strokeLinecap: "round",
    opacity: layer.opacity
  })));
}
Object.assign(__ds_scope, { Waveform });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/conversation/Waveform.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Primary action button. Variants: primary | tonal | ghost | destructive. */
function Button({
  variant = "primary",
  size = "md",
  disabled = false,
  icon = null,
  children,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const sizes = {
    sm: {
      height: 36,
      padding: "0 14px",
      fontSize: "var(--text-subhead)"
    },
    md: {
      height: "var(--height-control)",
      padding: "0 20px",
      fontSize: "var(--text-body)"
    },
    lg: {
      height: "var(--height-control-lg)",
      padding: "0 28px",
      fontSize: "var(--text-body)"
    }
  };
  const variants = {
    primary: {
      background: "var(--accent)",
      color: "var(--text-on-accent)"
    },
    tonal: {
      background: "var(--accent-soft)",
      color: "var(--text-accent)"
    },
    ghost: {
      background: "transparent",
      color: "var(--text-accent)"
    },
    destructive: {
      background: "var(--critical-soft)",
      color: "var(--critical)"
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    disabled: disabled,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      border: "none",
      borderRadius: "var(--radius-control)",
      fontWeight: "var(--weight-semibold)",
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.4 : 1,
      transform: pressed && !disabled ? "scale(0.97)" : "scale(1)",
      filter: pressed && !disabled ? "brightness(0.92)" : "none",
      transition: "transform var(--duration-fast) var(--ease-out), filter var(--duration-fast) var(--ease-out)",
      ...sizes[size],
      ...variants[variant],
      ...style
    }
  }, rest), icon, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
/** Surface container. Variants: card | raised | sheet. */
function Card({
  variant = "card",
  padding = "var(--space-4)",
  children,
  style
}) {
  const variants = {
    card: {
      background: "var(--surface-card)",
      borderRadius: "var(--radius-card)",
      boxShadow: "var(--shadow-card)"
    },
    raised: {
      background: "var(--surface-raised)",
      borderRadius: "var(--radius-card)",
      boxShadow: "var(--shadow-pop)"
    },
    sheet: {
      background: "var(--surface-sheet)",
      borderRadius: "var(--radius-sheet)",
      boxShadow: "var(--shadow-sheet)"
    }
  };
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding,
      ...variants[variant],
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
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
    tonal: {
      background: "var(--surface-raised)",
      color: "var(--text-primary)"
    },
    ghost: {
      background: "transparent",
      color: "var(--text-secondary)"
    },
    filled: {
      background: "var(--accent)",
      color: "var(--text-on-accent)"
    },
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      boxShadow: "inset 0 0 0 1px var(--hairline-strong)"
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    "aria-label": label,
    disabled: disabled,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
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
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/LanguageChip.jsx
try { (() => {
/** Language selector chip: label + change-affordance chevron. */
function LanguageChip({
  language,
  sublabel,
  active = false,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    onClick: onClick,
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      border: "none",
      background: active ? "var(--accent-soft)" : "transparent",
      color: active ? "var(--text-accent)" : "var(--text-primary)",
      padding: "8px 12px",
      borderRadius: "var(--radius-control)",
      fontSize: "var(--text-caption)",
      fontWeight: "var(--weight-semibold)",
      fontFamily: "inherit",
      letterSpacing: "var(--tracking-caps)",
      cursor: "pointer"
    }
  }, /*#__PURE__*/React.createElement("span", null, language), sublabel ? /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--text-faint)",
      fontWeight: "var(--weight-regular)"
    }
  }, sublabel) : null, /*#__PURE__*/React.createElement("svg", {
    width: "10",
    height: "6",
    viewBox: "0 0 10 6",
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l4 4 4-4",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "1.5",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    opacity: "0.6"
  })));
}
Object.assign(__ds_scope, { LanguageChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/LanguageChip.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
/** Pill-style mode switcher (翻译 / 对话 / 同声传译). Controlled. */
function SegmentedControl({
  segments = [],
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "tablist",
    style: {
      display: "inline-flex",
      gap: 4,
      padding: 4,
      background: "var(--surface-card)",
      borderRadius: "var(--radius-pill)",
      ...style
    }
  }, segments.map(seg => {
    const active = seg === value;
    return /*#__PURE__*/React.createElement("button", {
      key: seg,
      role: "tab",
      "aria-selected": active,
      onClick: () => onChange && onChange(seg),
      style: {
        border: "none",
        padding: "8px 16px",
        borderRadius: "var(--radius-pill)",
        fontSize: "var(--text-subhead)",
        fontWeight: "var(--weight-semibold)",
        fontFamily: "inherit",
        cursor: "pointer",
        background: active ? "var(--surface-raised)" : "transparent",
        color: active ? "var(--text-accent)" : "var(--text-secondary)",
        transition: "background var(--duration-fast) var(--ease-out), color var(--duration-fast) var(--ease-out)"
      }
    }, seg);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/core/Switch.jsx
try { (() => {
/** iOS-style switch. Controlled. */
function Switch({
  checked = false,
  onChange,
  disabled = false,
  label,
  style
}) {
  return /*#__PURE__*/React.createElement("button", {
    role: "switch",
    "aria-checked": checked,
    "aria-label": label,
    disabled: disabled,
    onClick: () => onChange && onChange(!checked),
    style: {
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
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      width: 27,
      height: 27,
      borderRadius: "50%",
      background: "#FFFFFF",
      boxShadow: "0 1px 3px rgba(0,0,0,0.3)",
      transform: checked ? "translateX(20px)" : "translateX(0)",
      transition: "transform var(--duration-base) var(--ease-out)"
    }
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Switch.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/ConversationScreen.jsx
try { (() => {
// VRecorder UI kit — Conversation screen. Light scope, hold-to-talk.
function ConversationScreen({
  onMode,
  onLive
}) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const {
    SegmentedControl,
    MessageBubble,
    HoldToTalkBar,
    Waveform,
    IconButton
  } = DS;
  const [held, setHeld] = React.useState(null);
  const [messages, setMessages] = React.useState([{
    role: "them",
    source: "开始吧，在底部按住说话翻译",
    translation: "Let's begin. Hold the button below to talk."
  }]);
  const release = () => {
    if (!held) return;
    const demo = held === "a" ? {
      role: "me",
      source: "请帮我翻译。",
      translation: "Please help me translate."
    } : {
      role: "them",
      source: "There is a lot of delicious food in China.",
      translation: "中国有很多美食。"
    };
    setMessages(m => [...m, demo]);
    setHeld(null);
  };
  return /*#__PURE__*/React.createElement("div", {
    "data-theme": "light",
    "data-screen-label": "\u5BF9\u8BDD Conversation",
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--surface-app)",
      display: "flex",
      flexDirection: "column",
      color: "var(--text-primary)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 54
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      padding: "0 16px"
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    segments: ["翻译", "对话", "同传"],
    value: "\u5BF9\u8BDD",
    onChange: onMode
  }), /*#__PURE__*/React.createElement(IconButton, {
    label: "\u66F4\u591A",
    variant: "ghost",
    size: 40
  }, /*#__PURE__*/React.createElement("svg", {
    width: "20",
    height: "20",
    viewBox: "0 0 24 24",
    fill: "currentColor"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "5",
    cy: "12",
    r: "1.8"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "12",
    r: "1.8"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "12",
    r: "1.8"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflow: "hidden",
      display: "flex",
      flexDirection: "column",
      gap: "var(--gap-bubble)",
      padding: "16px 16px 0",
      justifyContent: "flex-end"
    }
  }, messages.map((m, i) => /*#__PURE__*/React.createElement(MessageBubble, {
    key: i,
    role: m.role,
    source: m.source,
    translation: m.translation
  }))), held ? /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "10px 20px",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 6
    }
  }, /*#__PURE__*/React.createElement(Waveform, {
    state: "listening",
    color: "var(--live)",
    height: 28
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--text-faint)"
    }
  }, "\u677E\u624B\u7FFB\u8BD1 \xB7 \u4E0A\u6ED1\u53D6\u6D88")) : /*#__PURE__*/React.createElement("button", {
    onClick: onLive,
    style: {
      border: "none",
      background: "none",
      cursor: "pointer",
      padding: "12px 0 6px",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 2,
      color: "var(--text-faint)",
      fontFamily: "inherit",
      fontSize: "var(--text-caption)"
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M6 15l6-6 6 6"
  })), "\u4E0A\u62C9\u8FDB\u5165\u540C\u58F0\u4F20\u8BD1"), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "8px 16px 36px"
    }
  }, /*#__PURE__*/React.createElement(HoldToTalkBar, {
    sideA: "\u6309\u4F4F\u8BF4\u4E2D\u6587",
    sideB: "English",
    pressedSide: held,
    onPressStart: setHeld,
    onPressEnd: release
  })));
}
window.ConversationScreen = ConversationScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/ConversationScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/LanguageSheet.jsx
try { (() => {
// VRecorder UI kit — Language picker sheet (modal over any screen).
function LanguageSheet({
  open,
  selected,
  onSelect,
  onClose
}) {
  if (!open) return null;
  const recents = [{
    name: "中文 (普通话，简体)"
  }, {
    name: "英语 (美国)"
  }, {
    name: "日语",
    sublabel: "仅转写"
  }];
  const more = ["阿拉伯语", "德语", "法语", "韩语", "西班牙语 (西班牙)", "葡萄牙语 (巴西)", "泰语"];
  const row = (name, sublabel) => {
    const active = selected === name;
    return /*#__PURE__*/React.createElement("button", {
      key: name,
      onClick: () => onSelect(name),
      style: {
        display: "flex",
        alignItems: "center",
        gap: 10,
        width: "100%",
        border: "none",
        background: "none",
        cursor: "pointer",
        textAlign: "left",
        padding: "13px 4px",
        fontFamily: "inherit",
        color: "var(--text-primary)",
        borderBottom: "1px solid var(--hairline)"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 18,
        color: "var(--text-accent)"
      }
    }, active ? /*#__PURE__*/React.createElement("svg", {
      width: "16",
      height: "16",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      strokeWidth: "2.5",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M20 6L9 17l-5-5"
    })) : null), /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: "var(--text-body)"
      }
    }, name), sublabel ? /*#__PURE__*/React.createElement("span", {
      style: {
        fontSize: "var(--text-caption)",
        color: "var(--text-faint)"
      }
    }, sublabel) : null);
  };
  return /*#__PURE__*/React.createElement("div", {
    "data-screen-label": "\u8BED\u8A00\u9009\u62E9 Language sheet",
    onClick: onClose,
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--overlay-scrim)",
      backdropFilter: "blur(4px)",
      display: "flex",
      alignItems: "flex-end",
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      width: "100%",
      maxHeight: "72%",
      overflowY: "auto",
      background: "var(--surface-sheet)",
      borderRadius: "var(--radius-sheet) var(--radius-sheet) 0 0",
      boxShadow: "var(--shadow-sheet)",
      padding: "12px 20px 32px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 4,
      borderRadius: 2,
      background: "var(--hairline-strong)",
      margin: "0 auto 14px"
    }
  }), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: "0 0 6px",
      fontSize: "var(--text-caption)",
      color: "var(--text-faint)",
      letterSpacing: "var(--tracking-caps)"
    }
  }, "\u5E38\u7528"), recents.map(r => row(r.name, r.sublabel)), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: "18px 0 6px",
      fontSize: "var(--text-caption)",
      color: "var(--text-faint)",
      letterSpacing: "var(--tracking-caps)"
    }
  }, "\u5168\u90E8\u8BED\u8A00"), more.map(n => row(n))));
}
window.LanguageSheet = LanguageSheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/LanguageSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/LiveScreen.jsx
try { (() => {
// VRecorder UI kit — Live interpretation (同声传译). Dark, two-party split.
// onClose → exit chevron (full app); onSettings (no onClose) → gear, for the MVP where live IS the home screen.
function LiveScreen({
  onClose,
  onSettings
}) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const {
    TranscriptLine,
    WaterSurface,
    LiveBadge,
    IconButton,
    MicButton
  } = DS;
  const [listening, setListening] = React.useState(false);
  const [aLines, setALines] = React.useState([{
    status: "history",
    text: "中国有很多美食。"
  }]);
  const [bLines, setBLines] = React.useState([{
    status: "history",
    text: "There is a lot of delicious food in China."
  }]);
  const timers = React.useRef([]);
  React.useEffect(() => () => timers.current.forEach(clearTimeout), []);
  const simulate = () => {
    if (listening) {
      setListening(false);
      return;
    }
    setListening(true);
    const partialA = "重庆火锅很辣，但是…";
    const finalA = "重庆火锅很辣，但是很好吃！";
    const partialB = "Chongqing hot pot is spicy, but…";
    const finalB = "Chongqing hot pot is spicy, but delicious!";
    const push = (set, line) => set(ls => {
      const kept = ls.filter(l => l.status !== "partial").map(l => ({
        ...l,
        status: "history"
      }));
      return [...kept.slice(-2), line];
    });
    timers.current.push(setTimeout(() => {
      push(setALines, {
        status: "partial",
        text: partialA
      });
    }, 500));
    timers.current.push(setTimeout(() => {
      push(setBLines, {
        status: "partial",
        text: partialB
      });
    }, 1000));
    timers.current.push(setTimeout(() => {
      push(setALines, {
        status: "final",
        text: finalA
      });
    }, 2000));
    timers.current.push(setTimeout(() => {
      push(setBLines, {
        status: "final",
        text: finalB
      });
      setListening(false);
    }, 2600));
  };
  return /*#__PURE__*/React.createElement("div", {
    "data-screen-label": "\u540C\u58F0\u4F20\u8BD1 Live",
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--party-b-surface)",
      display: "grid",
      gridTemplateRows: "1fr 1fr",
      color: "var(--party-b-text)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      padding: "0 24px",
      display: "flex",
      flexDirection: "column",
      justifyContent: "flex-end",
      gap: 8,
      paddingBottom: 28
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 54,
      left: 12,
      right: 12,
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between"
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    label: onClose ? "退出同传" : "设置",
    variant: "ghost",
    size: 40,
    onClick: onClose || onSettings,
    style: {
      color: "var(--party-b-text-dim)"
    }
  }, onClose ? /*#__PURE__*/React.createElement("svg", {
    width: "20",
    height: "20",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M6 9l6 6 6-6"
  })) : /*#__PURE__*/React.createElement("svg", {
    width: "20",
    height: "20",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0 2-2z"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "12",
    r: "3"
  }))), /*#__PURE__*/React.createElement(LiveBadge, {
    label: "\u540C\u4F20\u4E2D"
  }), /*#__PURE__*/React.createElement(IconButton, {
    label: "\u5207\u6362\u8BED\u8A00",
    variant: "ghost",
    size: 40,
    style: {
      color: "var(--party-b-text-dim)"
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "20",
    height: "20",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M17 2l4 4-4 4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M3 6h18"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M7 22l-4-4 4-4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M21 18H3"
  })))), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--party-b-text-dim)",
      letterSpacing: "var(--tracking-caps)"
    }
  }, "ENGLISH"), bLines.map((l, i) => /*#__PURE__*/React.createElement(TranscriptLine, {
    key: i,
    status: l.status,
    text: l.text,
    onParty: "b"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--party-a-surface)",
      color: "var(--party-a-text)",
      padding: "28px 24px 0",
      display: "flex",
      flexDirection: "column",
      gap: 8,
      position: "relative"
    }
  }, /*#__PURE__*/React.createElement(WaterSurface, {
    state: listening ? "listening" : "idle",
    fill: "var(--party-a-surface)",
    height: 44,
    style: {
      position: "absolute",
      bottom: "100%",
      left: 0,
      right: 0,
      pointerEvents: "none"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--party-a-text-dim)",
      letterSpacing: "var(--tracking-caps)"
    }
  }, "\u4E2D\u6587 \xB7 \u666E\u901A\u8BDD"), listening && aLines.every(l => l.status === "history") ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: 0,
      fontSize: "var(--text-live-partial)",
      color: "var(--party-a-text-dim)",
      animation: "vr-thinking 1.4s var(--ease-breathe) infinite"
    }
  }, "\u8BF7\u5F00\u59CB\u8BF4\u8BDD\u5427") : null, aLines.map((l, i) => /*#__PURE__*/React.createElement(TranscriptLine, {
    key: i,
    status: l.status,
    text: l.text,
    onParty: "a"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: "auto",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 10,
      paddingBottom: 30
    }
  }, /*#__PURE__*/React.createElement(MicButton, {
    state: listening ? "listening" : "idle",
    size: 64,
    onClick: simulate
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--party-a-text-dim)"
    }
  }, "\u4E3A\u4FDD\u8BC1\u540C\u4F20\u6548\u679C\uFF0C\u8BF7\u9760\u8FD1\u9EA6\u514B\u98CE\u8BF4\u8BDD"))));
}
window.LiveScreen = LiveScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/LiveScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/SettingsScreen.jsx
try { (() => {
// VRecorder UI kit — Settings (设置). Light scope, iOS grouped lists.
function SettingsScreen({
  onBack
}) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const {
    Switch
  } = DS;
  const [engine, setEngine] = React.useState("Claude");
  const [stream, setStream] = React.useState(true);
  const [autoSpeak, setAutoSpeak] = React.useState(true);
  const [speed, setSpeed] = React.useState("1.0×");
  const [subSize, setSubSize] = React.useState("标准");
  const [transcribeOnly, setTranscribeOnly] = React.useState(false);
  const cycle = (value, options, set) => () => set(options[(options.indexOf(value) + 1) % options.length]);
  const chevron = /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round",
    style: {
      color: "var(--text-faint)",
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M9 6l6 6-6 6"
  }));
  const row = ({
    label,
    value,
    control,
    onClick,
    destructive,
    last,
    key
  }) => /*#__PURE__*/React.createElement("div", {
    key: key || label,
    onClick: onClick,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      minHeight: 50,
      padding: "0 16px",
      cursor: onClick ? "pointer" : "default",
      borderBottom: last ? "none" : "1px solid var(--hairline)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontSize: "var(--text-body)",
      color: destructive ? "var(--critical)" : "var(--text-primary)"
    }
  }, label), value ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-body)",
      color: "var(--text-faint)"
    }
  }, value) : null, control || null, onClick && !control ? chevron : null);
  const group = (caption, rows) => /*#__PURE__*/React.createElement("div", {
    key: caption,
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--text-faint)",
      letterSpacing: "var(--tracking-caps)",
      padding: "0 16px"
    }
  }, caption), /*#__PURE__*/React.createElement("div", {
    style: {
      background: "var(--surface-card)",
      borderRadius: "var(--radius-card)",
      boxShadow: "var(--shadow-card)",
      overflow: "hidden"
    }
  }, rows));
  return /*#__PURE__*/React.createElement("div", {
    "data-theme": "light",
    "data-screen-label": "\u8BBE\u7F6E Settings",
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--surface-app)",
      display: "flex",
      flexDirection: "column",
      color: "var(--text-primary)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 54
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6,
      padding: "4px 16px 10px"
    }
  }, onBack ? /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    "aria-label": "\u8FD4\u56DE",
    style: {
      border: "none",
      background: "none",
      cursor: "pointer",
      padding: 6,
      margin: "0 -6px",
      color: "var(--text-accent)",
      display: "flex"
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "22",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M15 6l-6 6 6 6"
  }))) : null, /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: 0,
      fontSize: "var(--text-title1)",
      fontWeight: "var(--weight-bold)",
      fontFamily: "var(--font-display)"
    }
  }, "\u8BBE\u7F6E")), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: "auto",
      padding: "6px 20px 40px",
      display: "flex",
      flexDirection: "column",
      gap: 24
    }
  }, group("翻译引擎", [row({
    label: "翻译服务",
    value: engine,
    onClick: cycle(engine, ["Claude", "OpenAI"], setEngine)
  }), row({
    label: "API 密钥",
    value: "已配置",
    onClick: () => {}
  }), row({
    label: "流式翻译",
    control: /*#__PURE__*/React.createElement(Switch, {
      checked: stream,
      onChange: setStream,
      label: "\u6D41\u5F0F\u7FFB\u8BD1"
    }),
    last: true
  })]), group("语音播报", [row({
    label: "自动播报译文",
    control: /*#__PURE__*/React.createElement(Switch, {
      checked: autoSpeak,
      onChange: setAutoSpeak,
      label: "\u81EA\u52A8\u64AD\u62A5\u8BD1\u6587"
    })
  }), row({
    label: "语速",
    value: speed,
    onClick: cycle(speed, ["0.8×", "1.0×", "1.2×"], setSpeed),
    last: true
  })]), group("同声传译", [row({
    label: "字幕字号",
    value: subSize,
    onClick: cycle(subSize, ["标准", "大", "特大"], setSubSize)
  }), row({
    label: "仅转写模式",
    control: /*#__PURE__*/React.createElement(Switch, {
      checked: transcribeOnly,
      onChange: setTranscribeOnly,
      label: "\u4EC5\u8F6C\u5199\u6A21\u5F0F"
    }),
    last: true
  })]), group("通用", [row({
    label: "历史记录",
    value: "保留 30 天",
    onClick: () => {}
  }), row({
    label: "清空翻译记录",
    destructive: true,
    onClick: () => {}
  }), row({
    label: "关于",
    value: "版本 1.0.0",
    onClick: () => {},
    last: true
  })])));
}
window.SettingsScreen = SettingsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/TranslateScreen.jsx
try { (() => {
// VRecorder UI kit — Translate (home) screen. Light scope.
function TranslateScreen({
  onOpenSheet,
  onMode,
  langA,
  langB
}) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const {
    SegmentedControl,
    LanguageChip,
    IconButton,
    Card,
    MicButton
  } = DS;
  const [text, setText] = React.useState("");
  return /*#__PURE__*/React.createElement("div", {
    "data-theme": "light",
    "data-screen-label": "\u7FFB\u8BD1 Translate",
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--surface-app)",
      display: "flex",
      flexDirection: "column",
      color: "var(--text-primary)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 54
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      padding: "0 16px"
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    segments: ["翻译", "对话", "同传"],
    value: "\u7FFB\u8BD1",
    onChange: onMode
  }), /*#__PURE__*/React.createElement(IconButton, {
    label: "\u4E2A\u4EBA",
    variant: "ghost",
    size: 40
  }, /*#__PURE__*/React.createElement("svg", {
    width: "20",
    height: "20",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "8",
    r: "4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M4 21c1.5-3.5 4.5-5 8-5s6.5 1.5 8 5"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      padding: "18px 20px 10px"
    }
  }, /*#__PURE__*/React.createElement(LanguageChip, {
    language: langA,
    onClick: onOpenSheet
  }), /*#__PURE__*/React.createElement(IconButton, {
    label: "\u4E92\u6362\u8BED\u8A00",
    variant: "tonal",
    size: 32
  }, /*#__PURE__*/React.createElement("svg", {
    width: "14",
    height: "14",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M17 2l4 4-4 4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M3 6h18"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M7 22l-4-4 4-4"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M21 18H3"
  }))), /*#__PURE__*/React.createElement(LanguageChip, {
    language: langB,
    onClick: onOpenSheet
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "0 20px"
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: "18px",
    style: {
      minHeight: 170,
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement("textarea", {
    value: text,
    onChange: e => setText(e.target.value),
    placeholder: "\u8F93\u5165\u6587\u672C",
    style: {
      flex: 1,
      border: "none",
      outline: "none",
      resize: "none",
      background: "transparent",
      fontFamily: "var(--font-ui)",
      fontSize: "var(--text-title3)",
      color: "var(--text-primary)",
      padding: 0
    }
  }), text ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: "10px 0 0",
      fontSize: "var(--text-title3)",
      fontWeight: "var(--weight-semibold)",
      color: "var(--text-accent)"
    }
  }, "Did you mean to translate this?") : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "flex-end",
      gap: 8,
      marginTop: 12
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    label: "\u62CD\u7167\u7FFB\u8BD1",
    variant: "tonal",
    size: 40
  }, /*#__PURE__*/React.createElement("svg", {
    width: "18",
    height: "18",
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: "2",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "12",
    cy: "13",
    r: "3"
  })))))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "14px 20px",
      display: "flex",
      flexDirection: "column",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-caption)",
      color: "var(--text-faint)",
      letterSpacing: "var(--tracking-caps)"
    }
  }, "\u6700\u8FD1"), /*#__PURE__*/React.createElement(Card, {
    padding: "14px 16px",
    style: {
      boxShadow: "none",
      background: "var(--surface-input)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-subhead)",
      color: "var(--text-secondary)"
    }
  }, "\u8BF7\u5E2E\u6211\u7FFB\u8BD1\u3002"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-body)",
      fontWeight: "var(--weight-semibold)"
    }
  }, "Please help me translate.")))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: "auto",
      display: "flex",
      justifyContent: "center",
      paddingBottom: 40
    }
  }, /*#__PURE__*/React.createElement(MicButton, {
    state: "idle",
    size: 72
  })));
}
window.TranslateScreen = TranslateScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/TranslateScreen.jsx", error: String((e && e.message) || e) }); }

__ds_ns.HoldToTalkBar = __ds_scope.HoldToTalkBar;

__ds_ns.LiveBadge = __ds_scope.LiveBadge;

__ds_ns.MessageBubble = __ds_scope.MessageBubble;

__ds_ns.MicButton = __ds_scope.MicButton;

__ds_ns.TranscriptLine = __ds_scope.TranscriptLine;

__ds_ns.WaterSurface = __ds_scope.WaterSurface;

__ds_ns.Waveform = __ds_scope.Waveform;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.LanguageChip = __ds_scope.LanguageChip;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Switch = __ds_scope.Switch;

})();
