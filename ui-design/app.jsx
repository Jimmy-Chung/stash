/* global React, Icon, ClipCard, Preferences */
const { useState: useS, useEffect: useE, useRef: useR, useMemo: useM, useCallback: useC } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "warm",
  "density": "default",
  "showShortcuts": true,
  "wallpaperSaturation": 1.05,
  "blurStrength": 50,
  "accentHue": 50
} /*EDITMODE-END*/;

function App() {
  const allClips = window.SAMPLE_CLIPS;
  const PINBOARDS = window.PINBOARDS;
  const TYPE_FILTERS = window.TYPE_FILTERS;

  // tweaks
  const [tweaks, setTweak] = window.useTweaks(TWEAK_DEFAULTS);

  const [open, setOpen] = useS(true);
  const [clips, setClips] = useS(allClips);
  const [pinned, setPinned] = useS(new Set(["c02", "c10"]));
  const [activePinboard, setActivePinboard] = useS("all");
  const [activeType, setActiveType] = useS("all");
  const [query, setQuery] = useS("");
  const [selected, setSelected] = useS(0);
  const [hoverPreview, setHoverPreview] = useS(null);
  const [ctxMenu, setCtxMenu] = useS(null);
  const [prefsOpen, setPrefsOpen] = useS(false);
  const [hotkey, setHotkey] = useS(["⌘", "⇧", "V"]);
  const [toast, setToast] = useS(null);
  const [newClipId, setNewClipId] = useS(null);

  const searchRef = useR(null);
  const carouselRef = useR(null);
  const previewTimer = useR(null);

  // filtered list
  const filtered = useM(() => {
    let list = clips;
    if (activePinboard !== "all") {
      list = list.filter((c) => c.pinboard === activePinboard);
    }
    if (activeType !== "all") {
      list = list.filter((c) => c.type === activeType);
    }
    if (query.trim()) {
      const q = query.toLowerCase();
      list = list.filter(
        (c) =>
        (c.title || "").toLowerCase().includes(q) ||
        (c.content || "").toLowerCase().includes(q) ||
        (c.app || "").toLowerCase().includes(q)
      );
    }
    // pinned first
    return [...list].sort((a, b) => {
      const ap = pinned.has(a.id) ? 0 : 1;
      const bp = pinned.has(b.id) ? 0 : 1;
      return ap - bp;
    });
  }, [clips, activePinboard, activeType, query, pinned]);

  // clamp selection
  useE(() => {
    if (selected >= filtered.length) setSelected(Math.max(0, filtered.length - 1));
  }, [filtered.length, selected]);

  // scroll selected into view
  useE(() => {
    const el = carouselRef.current?.querySelector(`[data-clip-id="${filtered[selected]?.id}"]`);
    if (el) el.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
  }, [selected, filtered]);

  // accent hue for CSS
  useE(() => {
    const root = document.documentElement;
    const h = tweaks.accentHue;
    root.style.setProperty("--accent", `oklch(0.72 0.16 ${h})`);
  }, [tweaks.accentHue]);

  const triggerPaste = useC((clip) => {
    if (!clip) return;
    setToast({ msg: `Pasted to ${clip.app === "Mail" || clip.app === "Notes" ? clip.app : "active app"}`, content: clip.title || clip.content });
    setTimeout(() => setToast(null), 1400);
    setTimeout(() => setOpen(false), 600);
  }, []);

  const togglePin = useC((id) => {
    setPinned((p) => {
      const n = new Set(p);
      n.has(id) ? n.delete(id) : n.add(id);
      return n;
    });
  }, []);

  const deleteClip = useC((id) => {
    setClips((cs) => cs.filter((c) => c.id !== id));
  }, []);

  // keyboard
  useE(() => {
    const onKey = (e) => {
      // global hotkey to open
      if (e.metaKey && e.shiftKey && e.key.toLowerCase() === "v") {
        e.preventDefault();
        setOpen(true);
        setTimeout(() => searchRef.current?.focus(), 200);
        return;
      }
      if (!open) return;

      // Esc — close
      if (e.key === "Escape") {
        if (ctxMenu) {setCtxMenu(null);return;}
        if (prefsOpen) {setPrefsOpen(false);return;}
        if (query) {setQuery("");searchRef.current?.blur();return;}
        setOpen(false);
        return;
      }
      // ⌘F focus search
      if (e.metaKey && e.key.toLowerCase() === "f") {
        e.preventDefault();
        searchRef.current?.focus();
        return;
      }
      // ⌘, prefs
      if (e.metaKey && e.key === ",") {
        e.preventDefault();
        setPrefsOpen(true);
        return;
      }
      // ⌘1-9 paste
      if (e.metaKey && /^[1-9]$/.test(e.key)) {
        e.preventDefault();
        const idx = parseInt(e.key, 10) - 1;
        if (filtered[idx]) {
          setSelected(idx);
          triggerPaste(filtered[idx]);
        }
        return;
      }
      // ⌘P pin
      if (e.metaKey && e.key.toLowerCase() === "p") {
        e.preventDefault();
        if (filtered[selected]) togglePin(filtered[selected].id);
        return;
      }
      // arrows
      const ae = document.activeElement;
      if (ae && ae.tagName === "INPUT") return;
      if (e.key === "ArrowRight") {
        e.preventDefault();
        setSelected((s) => Math.min(filtered.length - 1, s + 1));
      } else if (e.key === "ArrowLeft") {
        e.preventDefault();
        setSelected((s) => Math.max(0, s - 1));
      } else if (e.key === "Enter") {
        e.preventDefault();
        triggerPaste(filtered[selected]);
      } else if (e.key === "Backspace" || e.key === "Delete") {
        if (filtered[selected]) deleteClip(filtered[selected].id);
      } else if (e.key === " ") {
        e.preventDefault();
        setHoverPreview(filtered[selected]?.id);
      } else if (e.key === "[" && e.metaKey) {
        e.preventDefault();
        const idx = PINBOARDS.findIndex((p) => p.id === activePinboard);
        setActivePinboard(PINBOARDS[Math.max(0, idx - 1)].id);
      } else if (e.key === "]" && e.metaKey) {
        e.preventDefault();
        const idx = PINBOARDS.findIndex((p) => p.id === activePinboard);
        setActivePinboard(PINBOARDS[Math.min(PINBOARDS.length - 1, idx + 1)].id);
      }
    };
    const onUp = (e) => {
      if (e.key === " ") setHoverPreview(null);
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("keyup", onUp);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("keyup", onUp);
    };
  }, [open, filtered, selected, query, ctxMenu, prefsOpen, triggerPaste, togglePin, deleteClip, activePinboard, PINBOARDS]);

  // simulate new clip arriving when user clicks the demo button
  const simulateNewClip = useC(() => {
    const newClip = {
      id: "c-new-" + Date.now(),
      type: "text",
      title: "Just copied",
      content: "Stash captures every copy automatically — try summoning the gallery with ⌘⇧V from any app.",
      app: "Safari",
      appColor: "#1A8FFF",
      time: "Just now",
      pinboard: null
    };
    setClips((cs) => [newClip, ...cs]);
    setNewClipId(newClip.id);
    setSelected(0);
    setTimeout(() => setNewClipId(null), 800);
  }, []);

  return (
    <>
      <div className="desktop">
        <div className={`desktop-bg theme-${tweaks.theme}`} style={{ filter: `saturate(${tweaks.wallpaperSaturation})` }}></div>
        <div className="desktop-noise"></div>

        <div className="menubar">
          <span className="apple"></span>
          <span className="menu-item bold">Safari</span>
          <span className="menu-item">File</span>
          <span className="menu-item">Edit</span>
          <span className="menu-item">View</span>
          <span className="menu-item">History</span>
          <span className="menu-item">Bookmarks</span>
          <span className="menu-item">Window</span>
          <span className="menu-item">Help</span>
          <span className="spacer"></span>
          <span className="tray">
            <span className="stash-icon">STASH</span>
            <span>100%</span>
            <span style={{ fontVariantNumeric: "tabular-nums" }}>Tue Apr 27 · 14:32</span>
          </span>
        </div>

        {!open &&
        <div className="hotkey-hint">
            <div className="hotkey-card">
              <span style={{ opacity: 0.7 }}>Press</span>
              {hotkey.map((k, i) => <span key={i} className="kbd lg">{k}</span>)}
              <span style={{ opacity: 0.7 }}>to open Stash</span>
              <button
              className="icon-btn"
              style={{ marginLeft: 10 }}
              onClick={() => {setOpen(true);setTimeout(() => searchRef.current?.focus(), 200);}}
              aria-label="Open">
              
                <Icon name="search" size={14} />
              </button>
            </div>
            <button
            onClick={simulateNewClip}
            style={{
              pointerEvents: "auto",
              padding: "8px 14px",
              fontSize: 12,
              fontWeight: 500,
              color: "rgba(255,255,255,0.78)",
              background: "rgba(255,255,255,0.08)",
              border: "0.5px solid rgba(255,255,255,0.14)",
              borderRadius: 8,
              backdropFilter: "blur(20px)",
              cursor: "pointer",
              fontFamily: "inherit"
            }}>
            
              Simulate a new copy →
            </button>
          </div>
        }
      </div>

      <div className={`gallery ${open ? "open" : ""} ${tweaks.showShortcuts ? "show-shortcuts" : ""}`}>
        <div className="gallery-pane" style={{ backdropFilter: `blur(${tweaks.blurStrength}px) saturate(180%)`, WebkitBackdropFilter: `blur(${tweaks.blurStrength}px) saturate(180%)` }}>
          <div className="g-header">
            <div className="search-wrap">
              <Icon name="search" size={14} className="search-icon" />
              <input
                ref={searchRef}
                placeholder="Search clips, apps, or types…"
                value={query}
                onChange={(e) => setQuery(e.target.value)} />
              
              {!query && <span className="search-shortcut">⌘F</span>}
              {query &&
              <span style={{ cursor: "pointer", color: "rgba(255,255,255,0.5)" }} onClick={() => setQuery("")}>
                  <Icon name="x" size={13} />
                </span>
              }
            </div>

            <div className="type-pills">
              {TYPE_FILTERS.map((t) =>
              <button
                key={t.id}
                className={`type-pill ${activeType === t.id ? "active" : ""}`}
                onClick={() => setActiveType(t.id)}>
                
                  {t.label}
                </button>
              )}
            </div>

            <div className="divider"></div>

            <div className="toolbar-group">
              <button className="icon-btn" onClick={() => setPrefsOpen(true)} title="Preferences">
                <Icon name="settings" size={14} />
              </button>
            </div>
          </div>

          <div className="g-body">
            <div className="pinboards">
              <div className="pinboards-label">Pinboards</div>
              {PINBOARDS.map((pb) => {
                const liveCount =
                pb.id === "all" ?
                clips.length :
                clips.filter((c) => c.pinboard === pb.id).length;
                return (
                  <div
                    key={pb.id}
                    className={`pinboard ${activePinboard === pb.id ? "active" : ""}`}
                    onClick={() => setActivePinboard(pb.id)}>
                    
                    <span className="pb-icon" style={{ color: pb.accent || "rgba(255,255,255,0.7)" }}>
                      <Icon name={pb.icon} size={14} />
                    </span>
                    <span>{pb.label}</span>
                    <span className="pb-count">{liveCount}</span>
                  </div>);

              })}
              <div className="pinboard add">
                <span className="pb-icon"><Icon name="plus" size={13} /></span>
                <span>New Pinboard</span>
              </div>
            </div>

            <div className="carousel-wrap">
              {filtered.length === 0 ?
              <div className="empty">
                  <div className="big">⌕</div>
                  <div>No clips match "{query || activeType}"</div>
                  <div style={{ fontSize: 11.5, color: "rgba(255,255,255,0.4)" }}>
                    Try a different filter or clear your search
                  </div>
                </div> :

              <div className="carousel" ref={carouselRef}>
                  {filtered.map((clip, i) =>
                <ClipCard
                  key={clip.id}
                  clip={clip}
                  index={i}
                  selected={i === selected}
                  pinned={pinned.has(clip.id)}
                  query={query}
                  density={tweaks.density}
                  isNew={clip.id === newClipId}
                  onClick={() => {setSelected(i);}}
                  onContextMenu={(e) => {
                    e.preventDefault();
                    setSelected(i);
                    setCtxMenu({ x: e.clientX, y: e.clientY, clip });
                  }}
                  onMouseEnter={() => {
                    clearTimeout(previewTimer.current);
                    previewTimer.current = setTimeout(() => setHoverPreview(clip.id), 700);
                  }}
                  onMouseLeave={() => {
                    clearTimeout(previewTimer.current);
                    setHoverPreview(null);
                  }} />

                )}
                </div>
              }
            </div>
          </div>

          <div className="g-footer">
            <div className="hint"><span className="kbd">↵</span> Paste</div>
            <div className="hint"><span className="kbd">⌘</span><span className="kbd">1-9</span> Quick paste</div>
            <div className="hint"><span className="kbd">⌘</span><span className="kbd">P</span> Pin</div>
            <div className="hint"><span className="kbd">Space</span> Quick look</div>
            <div className="hint"><span className="kbd">⌫</span> Delete</div>
            <div className="spacer"></div>
            <div className="count">
              {filtered.length === clips.length ?
              `${clips.length} clips` :
              `${filtered.length} of ${clips.length}`}
              {pinned.size > 0 && ` · ${pinned.size} pinned`}
            </div>
          </div>
        </div>
      </div>

      {/* Hover preview overlay */}
      {hoverPreview && filtered.find((c) => c.id === hoverPreview) &&
      <PreviewOverlay clip={filtered.find((c) => c.id === hoverPreview)} onClose={() => setHoverPreview(null)} />
      }

      {/* Context menu */}
      {ctxMenu &&
      <ContextMenu
        x={ctxMenu.x}
        y={ctxMenu.y}
        clip={ctxMenu.clip}
        pinned={pinned.has(ctxMenu.clip.id)}
        onPaste={() => {triggerPaste(ctxMenu.clip);setCtxMenu(null);}}
        onPin={() => {togglePin(ctxMenu.clip.id);setCtxMenu(null);}}
        onDelete={() => {deleteClip(ctxMenu.clip.id);setCtxMenu(null);}}
        onClose={() => setCtxMenu(null)} />

      }

      {/* Preferences */}
      <Preferences
        open={prefsOpen}
        onClose={() => setPrefsOpen(false)}
        hotkey={hotkey}
        setHotkey={setHotkey} />
      

      {/* Toast */}
      <div className={`paste-toast ${toast ? "show" : ""}`}>
        <div className="check"><Icon name="check" size={13} stroke={2.5} /></div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 600 }}>{toast?.msg || ""}</div>
          {toast?.content &&
          <div style={{ fontSize: 11.5, color: "rgba(255,255,255,0.6)", marginTop: 2, maxWidth: 320, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
              {toast.content}
            </div>
          }
        </div>
      </div>

      <TweaksUI tweaks={tweaks} setTweak={setTweak} />
    </>);

}

function PreviewOverlay({ clip, onClose }) {
  return (
    <div className="preview-overlay show" onClick={onClose}>
      <div className="preview-card" onClick={(e) => e.stopPropagation()}>
        <div className="pc-head">
          <span className="app-dot" style={{ background: clip.appColor, width: 8, height: 8, borderRadius: "50%" }}></span>
          <span>{clip.title || clip.content.slice(0, 40)}</span>
          <span style={{ marginLeft: "auto", fontSize: 11.5, fontWeight: 400, color: "rgba(255,255,255,0.5)" }}>{clip.time}</span>
        </div>
        <div className="pc-body">
          {clip.type === "code" ?
          <window.CodeBlock content={clip.content} language={clip.language} /> :
          clip.type === "color" ?
          <div style={{ height: 280, borderRadius: 12, background: clip.content, display: "flex", alignItems: "flex-end", padding: 18 }}>
              <div style={{ background: "rgba(0,0,0,0.5)", padding: "8px 14px", borderRadius: 8, fontFamily: "SF Mono, monospace", fontWeight: 600 }}>
                {clip.content.toUpperCase()}
              </div>
            </div> :
          clip.type === "image" ?
          <div style={{
            height: 320,
            borderRadius: 12,
            background: "linear-gradient(135deg, #264653, #2a9d8f, #e9c46a, #f4a261)",
            position: "relative",
            overflow: "hidden"
          }}>
              <div style={{ position: "absolute", inset: 0, background: "repeating-linear-gradient(45deg, transparent 0, transparent 22px, rgba(255,255,255,0.07) 22px, rgba(255,255,255,0.07) 44px)" }}></div>
            </div> :

          <div style={{ whiteSpace: "pre-wrap", lineHeight: 1.6 }}>{clip.content}</div>
          }
        </div>
        <div className="pc-foot">
          <span className="app-chip">
            <span className="app-dot" style={{ background: clip.appColor }}></span>
            {clip.app}
          </span>
          <span>·</span>
          <span>{clip.type}</span>
          <span style={{ marginLeft: "auto", fontSize: 11.5 }}>
            Hold <span className="kbd" style={{ marginLeft: 4 }}>Space</span> to preview · release to dismiss
          </span>
        </div>
      </div>
    </div>);

}

function ContextMenu({ x, y, clip, pinned, onPaste, onPin, onDelete, onClose }) {
  const ref = useR();
  useE(() => {
    const onClick = (e) => {if (ref.current && !ref.current.contains(e.target)) onClose();};
    setTimeout(() => document.addEventListener("mousedown", onClick), 0);
    return () => document.removeEventListener("mousedown", onClick);
  }, [onClose]);

  // clamp
  const w = 240,h = 280;
  const left = Math.min(x, window.innerWidth - w - 10);
  const top = Math.min(y, window.innerHeight - h - 10);

  return (
    <div className="ctx-menu" ref={ref} style={{ left, top }}>
      <div className="ctx-item" onClick={onPaste}>
        <Icon name="check" size={13} className="ctx-icon" />
        Paste
        <span className="ctx-shortcut">↵</span>
      </div>
      <div className="ctx-item">
        <Icon name="copy" size={13} className="ctx-icon" />
        Copy again
        <span className="ctx-shortcut">⌘C</span>
      </div>
      <div className="ctx-divider"></div>
      <div className="ctx-item" onClick={onPin}>
        <Icon name="pin" size={13} className="ctx-icon" />
        {pinned ? "Unpin" : "Pin to top"}
        <span className="ctx-shortcut">⌘P</span>
      </div>
      <div className="ctx-item">
        <Icon name="palette" size={13} className="ctx-icon" />
        Move to Pinboard…
      </div>
      <div className="ctx-item">
        <Icon name="edit" size={13} className="ctx-icon" />
        Edit clip
        <span className="ctx-shortcut">⌘E</span>
      </div>
      <div className="ctx-item">
        <Icon name="share" size={13} className="ctx-icon" />
        Share…
      </div>
      <div className="ctx-divider"></div>
      <div className="ctx-item danger" onClick={onDelete}>
        <Icon name="trash" size={13} className="ctx-icon" />
        Delete
        <span className="ctx-shortcut">⌫</span>
      </div>
    </div>);

}

function TweaksUI({ tweaks, setTweak }) {
  const { TweaksPanel, TweakSection, TweakRadio, TweakToggle, TweakSlider } = window;
  return (
    <TweaksPanel>
      <TweakSection title="Visual">
        <TweakRadio
          label="Wallpaper"
          value={tweaks.theme}
          options={[
          { value: "warm", label: "Warm" },
          { value: "cool", label: "Cool" },
          { value: "mono", label: "Mono" }]
          }
          onChange={(v) => setTweak("theme", v)} />
        
        <TweakSlider
          label="Wallpaper saturation"
          value={tweaks.wallpaperSaturation}
          min={0.4} max={1.6} step={0.05}
          onChange={(v) => setTweak("wallpaperSaturation", v)} />
        
        <TweakSlider
          label="Glass blur"
          value={tweaks.blurStrength}
          min={10} max={80} step={2}
          onChange={(v) => setTweak("blurStrength", v)} />
        
        <TweakSlider
          label="Accent hue"
          value={tweaks.accentHue}
          min={0} max={360} step={5}
          onChange={(v) => setTweak("accentHue", v)} />
        
      </TweakSection>
      <TweakSection title="Layout">
        <TweakRadio
          label="Card density"
          value={tweaks.density}
          options={[
          { value: "compact", label: "Compact" },
          { value: "default", label: "Default" },
          { value: "cozy", label: "Cozy" }]
          }
          onChange={(v) => setTweak("density", v)} />
        
        <TweakToggle
          label="Always show ⌘1–9 shortcut chips"
          value={tweaks.showShortcuts}
          onChange={(v) => setTweak("showShortcuts", v)} />
        
      </TweakSection>
    </TweaksPanel>);

}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);