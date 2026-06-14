// VRecorder UI kit — Settings (设置). Light scope, iOS grouped lists.
function SettingsScreen({ onBack }) {
  const DS = window.VRecorderDesignSystem_e7fff0;
  const { Switch } = DS;
  const [engine, setEngine] = React.useState("Claude");
  const [stream, setStream] = React.useState(true);
  const [autoSpeak, setAutoSpeak] = React.useState(true);
  const [speed, setSpeed] = React.useState("1.0×");
  const [subSize, setSubSize] = React.useState("标准");
  const [transcribeOnly, setTranscribeOnly] = React.useState(false);

  const cycle = (value, options, set) => () =>
    set(options[(options.indexOf(value) + 1) % options.length]);

  const chevron = (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ color: "var(--text-faint)", flexShrink: 0 }}>
      <path d="M9 6l6 6-6 6"></path>
    </svg>
  );

  const row = ({ label, value, control, onClick, destructive, last, key }) => (
    <div
      key={key || label}
      onClick={onClick}
      style={{
        display: "flex", alignItems: "center", gap: 12, minHeight: 50,
        padding: "0 16px", cursor: onClick ? "pointer" : "default",
        borderBottom: last ? "none" : "1px solid var(--hairline)",
      }}
    >
      <span style={{ flex: 1, fontSize: "var(--text-body)", color: destructive ? "var(--critical)" : "var(--text-primary)" }}>{label}</span>
      {value ? <span style={{ fontSize: "var(--text-body)", color: "var(--text-faint)" }}>{value}</span> : null}
      {control || null}
      {onClick && !control ? chevron : null}
    </div>
  );

  const group = (caption, rows) => (
    <div key={caption} style={{ display: "flex", flexDirection: "column", gap: 8 }}>
      <span style={{ fontSize: "var(--text-caption)", color: "var(--text-faint)", letterSpacing: "var(--tracking-caps)", padding: "0 16px" }}>{caption}</span>
      <div style={{ background: "var(--surface-card)", borderRadius: "var(--radius-card)", boxShadow: "var(--shadow-card)", overflow: "hidden" }}>
        {rows}
      </div>
    </div>
  );

  return (
    <div data-theme="light" data-screen-label="设置 Settings" style={{
      position: "absolute", inset: 0, background: "var(--surface-app)",
      display: "flex", flexDirection: "column", color: "var(--text-primary)",
    }}>
      <div style={{ height: 54 }}></div>
      <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "4px 16px 10px" }}>
        {onBack ? (
          <button onClick={onBack} aria-label="返回" style={{ border: "none", background: "none", cursor: "pointer", padding: 6, margin: "0 -6px", color: "var(--text-accent)", display: "flex" }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6l-6 6 6 6"></path></svg>
          </button>
        ) : null}
        <h1 style={{ margin: 0, fontSize: "var(--text-title1)", fontWeight: "var(--weight-bold)", fontFamily: "var(--font-display)" }}>设置</h1>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "6px 20px 40px", display: "flex", flexDirection: "column", gap: 24 }}>
        {group("翻译引擎", [
          row({ label: "翻译服务", value: engine, onClick: cycle(engine, ["Claude", "OpenAI"], setEngine) }),
          row({ label: "API 密钥", value: "已配置", onClick: () => {} }),
          row({ label: "流式翻译", control: <Switch checked={stream} onChange={setStream} label="流式翻译" />, last: true }),
        ])}
        {group("语音播报", [
          row({ label: "自动播报译文", control: <Switch checked={autoSpeak} onChange={setAutoSpeak} label="自动播报译文" /> }),
          row({ label: "语速", value: speed, onClick: cycle(speed, ["0.8×", "1.0×", "1.2×"], setSpeed), last: true }),
        ])}
        {group("同声传译", [
          row({ label: "字幕字号", value: subSize, onClick: cycle(subSize, ["标准", "大", "特大"], setSubSize) }),
          row({ label: "仅转写模式", control: <Switch checked={transcribeOnly} onChange={setTranscribeOnly} label="仅转写模式" />, last: true }),
        ])}
        {group("通用", [
          row({ label: "历史记录", value: "保留 30 天", onClick: () => {} }),
          row({ label: "清空翻译记录", destructive: true, onClick: () => {} }),
          row({ label: "关于", value: "版本 1.0.0", onClick: () => {}, last: true }),
        ])}
      </div>
    </div>
  );
}
window.SettingsScreen = SettingsScreen;
