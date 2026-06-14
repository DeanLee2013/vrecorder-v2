// VRecorder UI kit — Live interpretation (同声传译). Dark, two-party split.
// onClose → exit chevron (full app); onSettings (no onClose) → gear, for the MVP where live IS the home screen.
function LiveScreen({ onClose, onSettings }) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const { TranscriptLine, WaterSurface, LiveBadge, IconButton, MicButton } = DS;
  const [listening, setListening] = React.useState(false);
  const [aLines, setALines] = React.useState([{ status: "history", text: "中国有很多美食。" }]);
  const [bLines, setBLines] = React.useState([{ status: "history", text: "There is a lot of delicious food in China." }]);
  const timers = React.useRef([]);

  React.useEffect(() => () => timers.current.forEach(clearTimeout), []);

  const simulate = () => {
    if (listening) { setListening(false); return; }
    setListening(true);
    const partialA = "重庆火锅很辣，但是…";
    const finalA = "重庆火锅很辣，但是很好吃！";
    const partialB = "Chongqing hot pot is spicy, but…";
    const finalB = "Chongqing hot pot is spicy, but delicious!";
    const push = (set, line) => set((ls) => {
      const kept = ls.filter((l) => l.status !== "partial").map((l) => ({ ...l, status: "history" }));
      return [...kept.slice(-2), line];
    });
    timers.current.push(setTimeout(() => { push(setALines, { status: "partial", text: partialA }); }, 500));
    timers.current.push(setTimeout(() => { push(setBLines, { status: "partial", text: partialB }); }, 1000));
    timers.current.push(setTimeout(() => { push(setALines, { status: "final", text: finalA }); }, 2000));
    timers.current.push(setTimeout(() => {
      push(setBLines, { status: "final", text: finalB });
      setListening(false);
    }, 2600));
  };

  return (
    <div data-screen-label="同声传译 Live" style={{
      position: "absolute", inset: 0, background: "var(--party-b-surface)",
      display: "grid", gridTemplateRows: "1fr 1fr", color: "var(--party-b-text)",
    }}>
      {/* Party B — counterpart (ink) */}
      <div style={{ position: "relative", padding: "0 24px", display: "flex", flexDirection: "column", justifyContent: "flex-end", gap: 8, paddingBottom: 28 }}>
        <div style={{ position: "absolute", top: 54, left: 12, right: 12, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <IconButton label={onClose ? "退出同传" : "设置"} variant="ghost" size={40} onClick={onClose || onSettings} style={{ color: "var(--party-b-text-dim)" }}>
            {onClose ? (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 9l6 6 6-6"></path></svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0 2-2z"></path><circle cx="12" cy="12" r="3"></circle></svg>
            )}
          </IconButton>
          <LiveBadge label="同传中" />
          <IconButton label="切换语言" variant="ghost" size={40} style={{ color: "var(--party-b-text-dim)" }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 2l4 4-4 4"></path><path d="M3 6h18"></path><path d="M7 22l-4-4 4-4"></path><path d="M21 18H3"></path></svg>
          </IconButton>
        </div>
        <span style={{ fontSize: "var(--text-caption)", color: "var(--party-b-text-dim)", letterSpacing: "var(--tracking-caps)" }}>ENGLISH</span>
        {bLines.map((l, i) => <TranscriptLine key={i} status={l.status} text={l.text} onParty="b" />)}
      </div>

      {/* Party A — you (violet): "water in a glass" — top edge ripples while listening */}
      <div style={{ background: "var(--party-a-surface)", color: "var(--party-a-text)", padding: "28px 24px 0", display: "flex", flexDirection: "column", gap: 8, position: "relative" }}>
        <WaterSurface
          state={listening ? "listening" : "idle"}
          fill="var(--party-a-surface)"
          height={44}
          style={{ position: "absolute", bottom: "100%", left: 0, right: 0, pointerEvents: "none" }}
        />
        <span style={{ fontSize: "var(--text-caption)", color: "var(--party-a-text-dim)", letterSpacing: "var(--tracking-caps)" }}>中文 · 普通话</span>
        {listening && aLines.every((l) => l.status === "history") ? (
          <p style={{ margin: 0, fontSize: "var(--text-live-partial)", color: "var(--party-a-text-dim)", animation: "vr-thinking 1.4s var(--ease-breathe) infinite" }}>请开始说话吧</p>
        ) : null}
        {aLines.map((l, i) => <TranscriptLine key={i} status={l.status} text={l.text} onParty="a" />)}
        <div style={{ marginTop: "auto", display: "flex", flexDirection: "column", alignItems: "center", gap: 10, paddingBottom: 30 }}>
          <MicButton state={listening ? "listening" : "idle"} size={64} onClick={simulate} />
          <span style={{ fontSize: "var(--text-caption)", color: "var(--party-a-text-dim)" }}>为保证同传效果，请靠近麦克风说话</span>
        </div>
      </div>
    </div>
  );
}
window.LiveScreen = LiveScreen;
