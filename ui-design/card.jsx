/* global React, Icon, highlight, CodeBlock, getDomain, hexToRgb, rgbToHsl */

function ClipCard({ clip, index, selected, pinned, query, density, showShortcuts, onClick, onContextMenu, onMouseEnter, onMouseLeave, isNew }) {
  const className = [
    "card",
    `density-${density}`,
    selected && "selected",
    pinned && "pinned",
    isNew && "new",
  ].filter(Boolean).join(" ");

  const shortcutLabel = index < 9 ? `⌘${index + 1}` : null;

  return (
    <div
      className={className}
      onClick={onClick}
      onContextMenu={onContextMenu}
      onMouseEnter={onMouseEnter}
      onMouseLeave={onMouseLeave}
      data-clip-id={clip.id}
    >
      {shortcutLabel && <div className="card-shortcut">{shortcutLabel}</div>}

      <div className="card-body">
        <CardContent clip={clip} query={query} />
      </div>

      <div className="card-footer">
        <div className="app-chip">
          <span className="app-dot" style={{ background: clip.appColor }}></span>
          <span>{clip.app}</span>
        </div>
        <div className="dot-sep"></div>
        <div className="time">{clip.time}</div>
      </div>
    </div>
  );
}

function CardContent({ clip, query }) {
  switch (clip.type) {
    case "text":
      return <div className="cb-text">{highlight(clip.content, query)}</div>;

    case "code":
      return (
        <div className="cb-code">
          <span className="cb-code-lang">{clip.language}</span>
          <CodeBlock content={clip.content} language={clip.language} />
        </div>
      );

    case "link": {
      const domain = getDomain(clip.content);
      return (
        <div className="cb-link">
          <div className="cb-link-thumb">
            <div className="cb-link-favicon" style={{ background: clip.favColor }}>
              {clip.favicon}
            </div>
          </div>
          <div className="cb-link-title">{highlight(clip.title, query)}</div>
          <div className="cb-link-domain">{domain}</div>
        </div>
      );
    }

    case "image":
      return (
        <div className="cb-image">
          <div className="cb-image-canvas">
            <div className="stripes"></div>
          </div>
          <div className="cb-image-meta">
            <span>{clip.dims}</span>
            <span>·</span>
            <span>{clip.size}</span>
          </div>
          {clip.swatch && (
            <div className="cb-image-swatches">
              {clip.swatch.map((c, i) => (
                <span key={i} style={{ background: c }} />
              ))}
            </div>
          )}
        </div>
      );

    case "color": {
      const [r, g, b] = hexToRgb(clip.content);
      const [h, s, l] = rgbToHsl(r, g, b);
      return (
        <div className="cb-color">
          <div className="cb-color-swatch" style={{ background: clip.content }}>
            <div className="cb-color-hex">{clip.content.toUpperCase()}</div>
          </div>
          <div className="cb-color-meta">
            <span>RGB</span><span>{r}, {g}, {b}</span>
            <span>HSL</span><span>{h}, {s}%, {l}%</span>
          </div>
        </div>
      );
    }

    case "file":
      return (
        <div className="cb-file">
          <div className="cb-file-icon">PDF</div>
          <div className="cb-file-name">{highlight(clip.title, query)}</div>
          <div style={{ fontSize: 11, color: "rgba(255,255,255,0.5)", fontFamily: "SF Mono, monospace" }}>
            {clip.size}
          </div>
        </div>
      );

    case "address":
      return <div className="cb-address">{highlight(clip.content, query)}</div>;

    default:
      return <div className="cb-text">{clip.content}</div>;
  }
}

Object.assign(window, { ClipCard });
