// overlay.js -- injected via Playwright addInitScript before Flutter boots.
// Exposes window.__floDemo helpers so walkthrough.mjs can drop highlight rings,
// a synthetic cursor, and click ripples onto whatever the browser paints.
//
// Design rules (see .cursor/plans/demo_v3_polish_overlays_e41b31ce.plan.md):
//   * Every overlay node is `position: fixed; pointer-events: none;
//     z-index: 2147483647`. Flutter paints to a <canvas>, so DOM overlays
//     always sit on top without interfering with the app.
//   * CSS keyframes live in one <style> tag written once per page load.
//   * Helpers are idempotent -- calling showRing twice just adds two rings.
//   * clearRings() removes only overlay ring nodes; cursor stays put so the
//     eye keeps tracking motion between scenes.
//   * addInitScript runs at document-start, when document.head / document.body
//     may not exist yet. All helpers fall back to document.documentElement
//     and re-attempt style injection on DOMContentLoaded, so no call throws.
(() => {
  if (typeof window === 'undefined' || typeof document === 'undefined') return;
  if (window.__floDemo && window.__floDemo.__ready) return;

  const NS_ID = '__floDemoStyle';
  const RING_CLASS = '__flo-demo-ring';
  const CURSOR_ID = '__flo-demo-cursor';
  const RIPPLE_CLASS = '__flo-demo-ripple';
  const LABEL_CLASS = '__flo-demo-label';
  const CURSOR_LABEL_ID = '__flo-demo-cursor-label';

  const CSS = `
    .${RING_CLASS} {
      position: fixed;
      pointer-events: none;
      border: 2px solid #10B981;
      border-radius: 12px;
      box-shadow:
        0 0 0 2px #10B981,
        0 0 30px 8px rgba(16, 185, 129, 0.55);
      z-index: 2147483646;
      animation: __floDemoRingPulse 1400ms ease-in-out infinite;
      transition: opacity 220ms ease-out;
    }
    .${LABEL_CLASS} {
      position: fixed;
      pointer-events: none;
      background: rgba(16, 185, 129, 0.95);
      color: #0B1120;
      font-family: 'Roboto', 'Segoe UI', system-ui, sans-serif;
      font-weight: 600;
      font-size: 15px;
      padding: 6px 12px;
      border-radius: 999px;
      box-shadow: 0 4px 14px rgba(0,0,0,0.35);
      z-index: 2147483646;
      transition: opacity 220ms ease-out;
      letter-spacing: 0.02em;
    }
    #${CURSOR_ID} {
      position: fixed;
      pointer-events: none;
      z-index: 2147483647;
      width: 26px;
      height: 34px;
      top: 0;
      left: 0;
      transform: translate3d(-9999px, -9999px, 0);
      filter: drop-shadow(0 3px 6px rgba(0,0,0,0.55));
      transition: transform 700ms cubic-bezier(0.22, 1, 0.36, 1);
    }
    .${RIPPLE_CLASS} {
      position: fixed;
      pointer-events: none;
      border-radius: 50%;
      background: radial-gradient(circle,
        rgba(16, 185, 129, 0.85) 0%,
        rgba(16, 185, 129, 0.55) 45%,
        rgba(16, 185, 129, 0.0) 75%);
      z-index: 2147483646;
      transform: translate(-50%, -50%) scale(0);
      opacity: 0.9;
      animation: __floDemoRipple 420ms ease-out forwards;
    }
    @keyframes __floDemoRingPulse {
      0%   { box-shadow: 0 0 0 2px #10B981, 0 0 20px 4px rgba(16,185,129,0.45); }
      50%  { box-shadow: 0 0 0 3px #10B981, 0 0 40px 12px rgba(16,185,129,0.7); }
      100% { box-shadow: 0 0 0 2px #10B981, 0 0 20px 4px rgba(16,185,129,0.45); }
    }
    @keyframes __floDemoRipple {
      0%   { transform: translate(-50%, -50%) scale(0.2); opacity: 0.85; }
      70%  { transform: translate(-50%, -50%) scale(4);   opacity: 0.35; }
      100% { transform: translate(-50%, -50%) scale(6);   opacity: 0; }
    }
    #${CURSOR_LABEL_ID} {
      position: fixed;
      pointer-events: none;
      background: rgba(15, 23, 42, 0.92);
      color: #F8FAFC;
      font-family: 'Roboto', 'Segoe UI', system-ui, sans-serif;
      font-weight: 500;
      font-size: 14px;
      padding: 5px 10px;
      border-radius: 8px;
      border: 1px solid rgba(16, 185, 129, 0.55);
      box-shadow: 0 4px 12px rgba(0,0,0,0.4);
      z-index: 2147483647;
      max-width: 280px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      opacity: 0;
      transition: opacity 180ms ease-out;
    }
  `;

  const injectStyleOnce = () => {
    try {
      if (document.getElementById(NS_ID)) return;
      const parent = document.head || document.documentElement;
      if (!parent) return; // will retry on DOMContentLoaded (see below)
      const style = document.createElement('style');
      style.id = NS_ID;
      style.textContent = CSS;
      parent.appendChild(style);
    } catch {
      // Ignore; helpers still function without CSS, they just look plain.
    }
  };

  const bodyOrRoot = () => document.body || document.documentElement;

  const clearRings = () => {
    injectStyleOnce();
    try {
      document
        .querySelectorAll('.' + RING_CLASS + ', .' + LABEL_CLASS)
        .forEach((el) => el.remove());
    } catch {
      // no-op
    }
  };

  const showRing = (opts) => {
    injectStyleOnce();
    if (!opts || typeof opts.x !== 'number') return;
    const parent = bodyOrRoot();
    if (!parent) return;
    const {
      x, y, w = 200, h = 80,
      label = '',
      labelPlacement = 'below',
    } = opts;
    const ring = document.createElement('div');
    ring.className = RING_CLASS;
    ring.style.left = x + 'px';
    ring.style.top = y + 'px';
    ring.style.width = w + 'px';
    ring.style.height = h + 'px';
    parent.appendChild(ring);

    if (label) {
      const chip = document.createElement('div');
      chip.className = LABEL_CLASS;
      chip.textContent = label;
      chip.style.left = x + 'px';
      chip.style.top = labelPlacement === 'above'
        ? Math.max(4, y - 34) + 'px'
        : (y + h + 8) + 'px';
      parent.appendChild(chip);
    }
  };

  const cursorSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 26 34" fill="none">' +
    '<path d="M2 2 L2 26 L9 20 L13 30 L17 28 L13 18 L22 18 Z"' +
    ' fill="#F8FAFC" stroke="#0F172A" stroke-width="1.6" stroke-linejoin="round"/>' +
    '</svg>';

  const ensureCursor = () => {
    const parent = bodyOrRoot();
    if (!parent) return null;
    let el = document.getElementById(CURSOR_ID);
    if (el) return el;
    el = document.createElement('div');
    el.id = CURSOR_ID;
    el.innerHTML = cursorSvg;
    parent.appendChild(el);
    return el;
  };

  const showCursor = () => {
    injectStyleOnce();
    const el = ensureCursor();
    if (!el) return;
    el.style.opacity = '1';
  };

  const hideCursor = () => {
    const el = document.getElementById(CURSOR_ID);
    if (el) el.style.opacity = '0';
  };

  const clearLabel = () => {
    try {
      const chip = document.getElementById(CURSOR_LABEL_ID);
      if (chip) chip.remove();
    } catch { /* no-op */ }
  };

  const showCursorLabel = (x, y, label) => {
    injectStyleOnce();
    const parent = bodyOrRoot();
    if (!parent || !label) return;
    clearLabel();
    const chip = document.createElement('div');
    chip.id = CURSOR_LABEL_ID;
    chip.textContent = label;
    chip.style.left = (x + 18) + 'px';
    chip.style.top = (y + 18) + 'px';
    chip.style.opacity = '1';
    parent.appendChild(chip);
  };

  // SVG arrow tip is at (2, 2) in the 26x34 viewBox (path starts "M2 2 ..."),
  // so translate3d must subtract (2, 2) — not (4, 4) — for the visual tip to
  // land exactly on the caller's (x, y). This keeps the synthetic cursor
  // aligned with `page.mouse` clicks (see click helpers in walkthrough.mjs).
  const TIP_X = 2;
  const TIP_Y = 2;

  const moveCursorTo = (opts) => {
    injectStyleOnce();
    const { x = 0, y = 0, durationMs = 700, label = '' } = opts || {};
    const el = ensureCursor();
    if (!el) return;
    el.style.transitionDuration = durationMs + 'ms';
    el.style.transform = 'translate3d(' + (x - TIP_X) + 'px, ' + (y - TIP_Y) + 'px, 0)';
    if (label) {
      showCursorLabel(x, y, label);
    } else {
      clearLabel();
    }
  };

  const clickRipple = (opts) => {
    injectStyleOnce();
    const parent = bodyOrRoot();
    if (!parent) return;
    const { x = 0, y = 0, durationMs = 420 } = opts || {};
    const dot = document.createElement('div');
    dot.className = RIPPLE_CLASS;
    dot.style.left = x + 'px';
    dot.style.top = y + 'px';
    dot.style.width = '80px';
    dot.style.height = '80px';
    dot.style.animationDuration = durationMs + 'ms';
    parent.appendChild(dot);
    setTimeout(() => { try { dot.remove(); } catch { /* no-op */ } }, durationMs + 100);
  };

  // Publish the API immediately, even if the DOM helpers can't touch <body>
  // yet -- the helpers themselves handle "body not ready" internally.
  window.__floDemo = {
    __ready: true,
    showRing,
    clearRings,
    showCursor,
    hideCursor,
    moveCursorTo,
    clickRipple,
    clearLabel,
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectStyleOnce, { once: true });
  } else {
    injectStyleOnce();
  }
})();
