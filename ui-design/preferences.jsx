/* global React, Icon */
const { useState: usePrefsState } = React;

function Preferences({ open, onClose, hotkey, setHotkey }) {
  const [tab, setTab] = usePrefsState("general");
  const [recording, setRecording] = usePrefsState(false);
  const [prefs, setPrefs] = usePrefsState({
    launchAtLogin: true,
    showInMenubar: true,
    historySize: "500",
    soundOnPaste: false,
    pasteAsPlainText: true,
    excludePasswords: true,
    syncEnabled: true,
    encryptSync: true,
  });

  const togglePref = (k) => setPrefs((p) => ({ ...p, [k]: !p[k] }));

  // capture key when recording
  React.useEffect(() => {
    if (!recording) return;
    const onKey = (e) => {
      e.preventDefault();
      const parts = [];
      if (e.metaKey) parts.push("⌘");
      if (e.ctrlKey) parts.push("⌃");
      if (e.altKey) parts.push("⌥");
      if (e.shiftKey) parts.push("⇧");
      if (e.key && e.key.length === 1) parts.push(e.key.toUpperCase());
      else if (e.key === "Space") parts.push("Space");
      else if (!["Meta","Control","Alt","Shift"].includes(e.key)) parts.push(e.key);
      if (parts.length >= 2) {
        setHotkey(parts);
        setRecording(false);
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => window.removeEventListener("keydown", onKey, true);
  }, [recording, setHotkey]);

  if (!open) return null;

  return (
    <div className={`prefs-backdrop ${open ? "open" : ""}`} onClick={onClose}>
      <div className="prefs-window" onClick={(e) => e.stopPropagation()}>
        <div className="prefs-titlebar">
          <div className="traffic">
            <span onClick={onClose}></span>
            <span></span>
            <span></span>
          </div>
          <div className="ttl">Preferences</div>
        </div>

        <div className="prefs-tabs">
          {[
            { id: "general", label: "General", icon: "settings" },
            { id: "shortcuts", label: "Shortcuts", icon: "kbd" },
            { id: "sync", label: "Sync", icon: "cloud" },
            { id: "privacy", label: "Privacy", icon: "heart" },
          ].map((t) => (
            <button
              key={t.id}
              className={`prefs-tab ${tab === t.id ? "active" : ""}`}
              onClick={() => setTab(t.id)}
            >
              <div className="icon-circle"><Icon name={t.icon} size={14} stroke={2} /></div>
              {t.label}
            </button>
          ))}
        </div>

        <div className="prefs-body">
          {tab === "general" && (
            <>
              <div className="prefs-row">
                <div className="prefs-label">
                  Launch at login
                  <div className="prefs-help">Stash starts when you log into your Mac</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.launchAtLogin ? "on" : ""}`} onClick={() => togglePref("launchAtLogin")}></div>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  Show in menu bar
                  <div className="prefs-help">Display the Stash icon next to the clock</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.showInMenubar ? "on" : ""}`} onClick={() => togglePref("showInMenubar")}></div>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  History size
                  <div className="prefs-help">How many clips to remember locally</div>
                </div>
                <div className="prefs-control">
                  <select className="select" value={prefs.historySize} onChange={(e) => setPrefs({ ...prefs, historySize: e.target.value })}>
                    <option value="100">100 clips</option>
                    <option value="500">500 clips</option>
                    <option value="1000">1,000 clips</option>
                    <option value="unlimited">Unlimited</option>
                  </select>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  Paste as plain text
                  <div className="prefs-help">Strip formatting on ⌘V; ⇧⌘V keeps it</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.pasteAsPlainText ? "on" : ""}`} onClick={() => togglePref("pasteAsPlainText")}></div>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  Sound on paste
                  <div className="prefs-help">Play a subtle confirmation sound</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.soundOnPaste ? "on" : ""}`} onClick={() => togglePref("soundOnPaste")}></div>
                </div>
              </div>
            </>
          )}

          {tab === "shortcuts" && (
            <>
              <div className="prefs-row">
                <div className="prefs-label">
                  Open Stash
                  <div className="prefs-help">Global hotkey to summon the gallery</div>
                </div>
                <div className="prefs-control">
                  <div
                    className={`kbd-recorder ${recording ? "recording" : ""}`}
                    onClick={() => setRecording((r) => !r)}
                  >
                    {recording ? (
                      <span style={{ color: "#f4a261", fontSize: 12, fontWeight: 500 }}>Press keys…</span>
                    ) : (
                      hotkey.map((k, i) => <span key={i} className="kbd">{k}</span>)
                    )}
                  </div>
                </div>
              </div>

              <div style={{ marginTop: 18 }}>
                <div className="prefs-label" style={{ marginBottom: 4 }}>While Stash is open</div>
                {[
                  { name: "Paste selected", desc: "Paste highlighted clip into the previous app", keys: ["↵"] },
                  { name: "Quick paste", desc: "Paste clip at position 1–9 directly", keys: ["⌘", "1–9"] },
                  { name: "Pin / unpin", desc: "Toggle pin on the selected clip", keys: ["⌘", "P"] },
                  { name: "Quick look", desc: "Hold to enlarge the selected clip", keys: ["Space"] },
                  { name: "Search", desc: "Focus the search field", keys: ["⌘", "F"] },
                  { name: "Move between Pinboards", desc: "Cycle through your boards", keys: ["⌘", "[", "]"] },
                  { name: "Delete clip", desc: "Remove the selected clip from history", keys: ["⌫"] },
                  { name: "Close", desc: "Hide the gallery", keys: ["esc"] },
                ].map((s, i) => (
                  <div key={i} className="shortcut-row">
                    <div>
                      <div className="name">{s.name}</div>
                      <div className="desc">{s.desc}</div>
                    </div>
                    <div style={{ display: "flex", gap: 4 }}>
                      {s.keys.map((k, j) => <span key={j} className="kbd">{k}</span>)}
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}

          {tab === "sync" && (
            <>
              <div className="sync-card">
                <div className="sync-avatar">AC</div>
                <div className="sync-details">
                  <div className="sync-name">Ada Chen</div>
                  <div className="sync-email">ada@example.com · Stash Cloud</div>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#4ade80" }}>
                  <span style={{ width: 7, height: 7, borderRadius: "50%", background: "#4ade80" }}></span>
                  Synced just now
                </div>
              </div>

              <div className="sync-stat-grid">
                <div className="sync-stat">
                  <div className="num">487</div>
                  <div className="lbl">Clips synced</div>
                </div>
                <div className="sync-stat">
                  <div className="num">3</div>
                  <div className="lbl">Devices</div>
                </div>
                <div className="sync-stat">
                  <div className="num">12 MB</div>
                  <div className="lbl">Used of 5 GB</div>
                </div>
              </div>

              <div className="prefs-row">
                <div className="prefs-label">
                  End-to-end encryption
                  <div className="prefs-help">Clips are encrypted on your device before upload</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.encryptSync ? "on" : ""}`} onClick={() => togglePref("encryptSync")}></div>
                </div>
              </div>

              <div style={{ marginTop: 18 }}>
                <div className="prefs-label" style={{ marginBottom: 8 }}>Trusted devices</div>
                {[
                  { name: "Ada's MacBook Pro", meta: "macOS 15.2 · This device", icon: "macbook", status: "online" },
                  { name: "Ada's iPhone", meta: "iOS 18.3 · 2 min ago", icon: "iphone", status: "online" },
                  { name: "Ada's iPad Air", meta: "iPadOS 18.2 · 3 days ago", icon: "ipad", status: "offline" },
                ].map((d, i) => (
                  <div key={i} className="device-row">
                    <div className="dev-icon"><Icon name={d.icon} size={14} /></div>
                    <div className="dev-info">
                      <div style={{ fontWeight: 500 }}>{d.name}</div>
                      <div style={{ fontSize: 11, color: "rgba(255,255,255,0.5)", marginTop: 2 }}>{d.meta}</div>
                    </div>
                    <div className={`dev-status ${d.status}`}>{d.status === "online" ? "Online" : "Offline"}</div>
                  </div>
                ))}
              </div>
            </>
          )}

          {tab === "privacy" && (
            <>
              <div className="prefs-row">
                <div className="prefs-label">
                  Exclude password fields
                  <div className="prefs-help">Don't capture clipboard data from password managers</div>
                </div>
                <div className="prefs-control">
                  <div className={`toggle ${prefs.excludePasswords ? "on" : ""}`} onClick={() => togglePref("excludePasswords")}></div>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  Excluded apps
                  <div className="prefs-help">Stash won't record clipboards from these apps</div>
                </div>
                <div className="prefs-control" style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
                  {["1Password", "Keychain", "Bitwarden", "Banking apps"].map((a) => (
                    <span key={a} style={{
                      padding: "4px 10px",
                      borderRadius: 6,
                      background: "rgba(255,255,255,0.06)",
                      fontSize: 12,
                      border: "0.5px solid rgba(255,255,255,0.08)",
                    }}>{a}</span>
                  ))}
                  <span style={{
                    padding: "4px 10px",
                    borderRadius: 6,
                    background: "transparent",
                    fontSize: 12,
                    border: "0.5px dashed rgba(255,255,255,0.2)",
                    color: "rgba(255,255,255,0.5)",
                    cursor: "pointer",
                  }}>+ Add app</span>
                </div>
              </div>
              <div className="prefs-row">
                <div className="prefs-label">
                  Auto-clear after
                  <div className="prefs-help">Older clips are removed automatically</div>
                </div>
                <div className="prefs-control">
                  <select className="select" defaultValue="never">
                    <option value="day">24 hours</option>
                    <option value="week">7 days</option>
                    <option value="month">30 days</option>
                    <option value="never">Never</option>
                  </select>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

window.Preferences = Preferences;
