'use strict';
let currentClient = '';
const clientDataMap = new Map();
const clientActivityMap = new Map();
const clientCanvases = new Map(); // key -> 2D context of the card canvas
const deviceEls = new Map();      // key -> card element (cards are reused, never rebuilt)
const thumbStreams = new Map();   // key -> { ws, pending, last, busy, retry, closed }
const textDecoder = new TextDecoder('utf-8');
const textEncoder = new TextEncoder();
let ws = null;
let wsReady = false;
let lastListJson = '';            // skip re-processing when the client list did not change
let sortDir = 'asc';              // 'asc' | 'desc' - PCs are sorted by name (natural order: PC2 before PC10)
let filterText = '';              // search box text (lower-case)
const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: 'base' });

// WebSocket URL builder: localhost / IP address -> port 2050, domain -> same host as the page.
// Uses wss:// automatically when the page is served over HTTPS.
function buildWsUrl(path) {
    const { protocol, hostname, host } = window.location;
    const proto = protocol === 'https:' ? 'wss://' : 'ws://';
    const isLocalOrIp = hostname === 'localhost'
        || /^\d{1,3}(\.\d{1,3}){3}$/.test(hostname)   // IPv4, e.g. 192.168.1.10
        || hostname.startsWith('[');                    // IPv6, e.g. [::1]
    return proto + (isLocalOrIp ? hostname + ':2050' : host) + path;
}

// UI & Clock Helpers
const getEl = (id) => document.getElementById(id);
setInterval(() => {
    const clock = getEl('clock');
    if (clock) clock.textContent = new Date().toLocaleTimeString('en-US', { hour12: false });
}, 1000);

document.addEventListener('click', (e) => {
    const sidebar = getEl('detailsSidebar');
    if (sidebar?.classList.contains('visible') && !sidebar.contains(e.target) && !e.target.closest('.device-entry')) {
        deselectDevice();
    }
});

// Unified Data Binding Function
function updateInfo(data = {}) {
    const getVal = (...keys) => {
        for (const k of keys) if (data[k] !== undefined && data[k] !== null) return data[k];
        return '—';
    };

    const name = getVal('clientName', 'ClientName');
    const fields = {
        Username: name !== '—' ? name.toUpperCase() : '—',
        MachineName: getVal('machineName', 'MachineName'),
        Workgroup: getVal('workGroup', 'WorkGroup'),
        Windows: getVal('windows', 'Windows'),
        WindowsVersion: getVal('windowsVersion', 'WindowsVersion'),
        OSVersion: getVal('osVersion', 'OSVersion'),
        OSArchitecture: getVal('osArchitecture', 'OSArchitecture'),
        SerialNumber: getVal('serialNumber', 'SerialNumber'),
        ProcessorCount: getVal('processorCount', 'ProcessorCount'),
        ScreenCount: getVal('screenCount', 'ScreenCount'),
        ActiveWindow: getVal('windowTitle', 'WindowTitle')
    };

    Object.entries(fields).forEach(([id, val]) => {
        const el = getEl(id);
        if (el) el.textContent = val;
    });
}

// ---------------------------------------------------------------------------
// Main WebSocket (client list + activity only)
// ---------------------------------------------------------------------------
function connectWebSocket() {
    ws = new WebSocket(buildWsUrl('/ws/browser'));
    ws.binaryType = 'arraybuffer';

    ws.onopen = () => {
        wsReady = true;
    };

    ws.onmessage = (e) => {
        if (!(e.data instanceof ArrayBuffer) || !e.data.byteLength) return;
        const bytes = new Uint8Array(e.data);
        const type = bytes[0];

        // Frames are handled by the per-client thumbnail sockets
        if (type === 0x10) return;

        try {
            const data = JSON.parse(textDecoder.decode(bytes.subarray(1)));
            if (type === 0x11) handleClientListUpdate(data);
            if (type === 0x12) handleActivityUpdate(data);
        } catch (err) {
            console.error('WS Parse Error:', err);
        }
    };

    ws.onerror = () => { try { ws.close(); } catch { } };

    ws.onclose = () => {
        wsReady = false;
        clearTimeout(ws._retry);
        ws._retry = setTimeout(connectWebSocket, 3000);
    };
}

// ---------------------------------------------------------------------------
// Per-client thumbnail streams (one socket per card, same method as Remote.html)
// ---------------------------------------------------------------------------

// Remote.html strips the first space from the client name, so do the same here
const thumbSubKey = (key) => `screen_1_${key.replace(' ', '')}`;

// Performance tuning for the card thumbnails
const THUMB_MAX_W = 1280;   // upper limit for the decoded width (raise for even sharper cards)
const THUMB_MIN_W = 480;    // lower limit
const THUMB_RESIZE = 'medium'; // 'low' | 'medium' | 'high' - resize quality (high = sharpest)
let thumbTargetW = 640;    // updated automatically from the real card size x devicePixelRatio

// Decode at the size the card is really displayed (sharp on retina / full-width mobile cards)
function updateThumbTarget() {
    const box = document.querySelector('.device-entry:not(.is-hidden) .screen-preview-container');
    const w = box ? box.clientWidth : 0;
    if (!w) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 3);
    thumbTargetW = Math.max(THUMB_MIN_W, Math.min(THUMB_MAX_W, Math.ceil(w * dpr)));
}
window.addEventListener('resize', updateThumbTarget);
const THUMB_FPS = 100;     // max thumbnail repaint rate per card
const THUMB_MIN_MS = 1000 / THUMB_FPS;
const PAUSE_DELAY = 3000;   // ms a card must stay off-screen before its stream is paused

const visibleKeys = new Set(); // cards currently in the viewport
const dirtyKeys = new Set(); // cards with a new frame waiting to be painted
let rafId = 0;

// Only cards that are actually visible need live video
const io = ('IntersectionObserver' in window)
    ? new IntersectionObserver((entries) => {
        entries.forEach((en) => {
            const key = en.target.dataset.name.toUpperCase();
            if (en.isIntersecting) visibleKeys.add(key); else visibleKeys.delete(key);
            updateStreamState(key);
        });
    }, { rootMargin: '150px' })
    : null;

const shouldRun = (key) => !io || (!document.hidden && visibleKeys.has(key));

function updateStreamState(key) {
    const s = thumbStreams.get(key);
    if (!s || s.closed) return;
    if (shouldRun(key)) {
        resumeThumbStream(key);
    } else if (!s.paused && !s.pauseTimer) {
        // small delay so quick scrolling does not reconnect sockets repeatedly
        s.pauseTimer = setTimeout(() => pauseThumbStream(key), document.hidden ? 0 : PAUSE_DELAY);
    }
}

function pauseThumbStream(key) {
    const s = thumbStreams.get(key);
    if (!s) return;
    clearTimeout(s.pauseTimer); s.pauseTimer = null;
    if (s.paused || shouldRun(key)) return;
    s.paused = true;
    clearTimeout(s.retry);
    const sock = s.ws;
    s.ws = null;                       // marks the old socket as stale (see handlers)
    s.pending = null;
    dirtyKeys.delete(key);
    try { sock?.close(); } catch { }
}

function resumeThumbStream(key) {
    const s = thumbStreams.get(key);
    if (!s || s.closed) return;
    clearTimeout(s.pauseTimer); s.pauseTimer = null;
    if (!s.paused) return;
    s.paused = false;
    s.connect();
    if (s.last) { s.pending = s.last; scheduleDraw(key); } // show the cached frame right away
}

function openThumbStream(key) {
    if (thumbStreams.has(key)) return;
    const s = {
        ws: null, pending: null, last: null, busy: false, retry: null, closed: false,
        paused: true, pauseTimer: null, lastDraw: 0, connect: null
    };
    thumbStreams.set(key, s);

    s.connect = () => {
        if (s.closed || s.paused || s.ws) return;
        const sock = new WebSocket(buildWsUrl('/ws/browser'));
        sock.binaryType = 'arraybuffer';
        s.ws = sock;

        sock.onopen = () => {
            if (s.ws !== sock) { try { sock.close(); } catch { } return; }
            const kb = textEncoder.encode(thumbSubKey(key));
            const msg = new Uint8Array(1 + kb.length);
            msg[0] = 0x21; // Subscription header flag
            msg.set(kb, 1);
            sock.send(msg.buffer);
        };

        sock.onmessage = (e) => {
            if (s.ws !== sock) return; // stale socket
            if (!(e.data instanceof ArrayBuffer) || !e.data.byteLength) return;
            if (new Uint8Array(e.data, 0, 1)[0] !== 0x10) return; // ignore 0x11 / 0x12 here
            s.pending = e.data; // keep only the latest frame
            s.last = e.data;    // cache so the card can be repainted after a re-render / resume
            scheduleDraw(key);
        };

        sock.onclose = () => {
            if (s.ws !== sock) return;  // closed on purpose (paused) or replaced
            s.ws = null;
            if (!s.closed && !s.paused) s.retry = setTimeout(s.connect, 3000);
        };
    };

    // Start only if the card is already known to be visible; otherwise the observer will resume it
    if (shouldRun(key) && (!io || visibleKeys.has(key))) { s.paused = false; s.connect(); }
}

function closeThumbStream(key) {
    const s = thumbStreams.get(key);
    if (!s) return;
    s.closed = true;
    clearTimeout(s.retry);
    clearTimeout(s.pauseTimer);
    dirtyKeys.delete(key);
    visibleKeys.delete(key);
    const sock = s.ws;
    s.ws = null;
    try { sock?.close(); } catch { }
    thumbStreams.delete(key);
}

function syncThumbStreams(keys) {
    const wanted = new Set(keys);
    [...thumbStreams.keys()].forEach((k) => { if (!wanted.has(k)) closeThumbStream(k); });
    keys.forEach(openThumbStream);
}

// Pause everything while the tab is in the background, resume when it comes back
document.addEventListener('visibilitychange', () => {
    [...thumbStreams.keys()].forEach(updateStreamState);
});

// ---------------------------------------------------------------------------
// Painting: one shared rAF loop, throttled per card, downscaled decode
// ---------------------------------------------------------------------------
function scheduleDraw(key) {
    dirtyKeys.add(key);
    if (!rafId) rafId = requestAnimationFrame(drawLoop);
}

function drawLoop(now) {
    rafId = 0;
    let waiting = false;

    dirtyKeys.forEach((key) => {
        const s = thumbStreams.get(key);
        if (!s || !s.pending || !clientCanvases.has(key)) { dirtyKeys.delete(key); return; }
        if (s.busy) { dirtyKeys.delete(key); return; }               // finishes -> reschedules itself
        if (now - s.lastDraw < THUMB_MIN_MS) { waiting = true; return; } // too soon, try next frame
        dirtyKeys.delete(key);
        s.lastDraw = now;
        decodeAndDraw(key, s);
    });

    if (waiting) rafId = requestAnimationFrame(drawLoop);
}

function decodeAndDraw(key, s) {
    const buf = s.pending;
    s.pending = null;
    s.busy = true;

    const blob = new Blob([new Uint8Array(buf, 1)], { type: 'image/jpeg' });

    // Ask the browser to decode straight to thumbnail size (falls back to full size if unsupported)
    const targetW = thumbTargetW;
    createImageBitmap(blob, { resizeWidth: targetW, resizeQuality: THUMB_RESIZE })
        .catch(() => createImageBitmap(blob))
        .then((bm) => {
            const ctx = clientCanvases.get(key); // look up again in case the list re-rendered
            if (ctx) {
                const w = Math.min(bm.width, targetW);
                const h = Math.max(1, Math.round(bm.height * w / bm.width));
                const c = ctx.canvas;
                if (c.width !== w || c.height !== h) { c.width = w; c.height = h; }
                ctx.imageSmoothingQuality = 'high';
                ctx.drawImage(bm, 0, 0, w, h);
            }
            bm.close();
        })
        .catch(() => { })
        .finally(() => {
            s.busy = false;
            if (s.pending) scheduleDraw(key);
        });
}

// ---------------------------------------------------------------------------
// Client list / activity handlers
// ---------------------------------------------------------------------------
function handleClientListUpdate(clients) {
    // Nothing changed -> nothing to do (avoids needless work on repeated broadcasts)
    const json = JSON.stringify(clients);
    if (json === lastListJson) return;
    lastListJson = json;

    clientDataMap.clear();
    clients.forEach((c) => {
        if (c.ClientName) clientDataMap.set(c.ClientName.toUpperCase(), c);
    });

    renderDevices(clients); // updates cards in place, canvases are kept
    syncThumbStreams([...clientDataMap.keys()]);

    if (currentClient && clientDataMap.has(currentClient)) {
        selectDevice(currentClient);
    }
}

function handleActivityUpdate(activity) {
    const name = activity?.clientName || activity?.ClientName;
    if (!name) return;
    const accountKey = name.toUpperCase();

    clientActivityMap.set(accountKey, activity);

    const subEl = getEl(`sub-${accountKey}`);
    if (subEl) subEl.textContent = activity.windowTitle || activity.appName || 'Online';
    if (filterText) organizeDevices();

    if (currentClient === accountKey) {
        selectDevice(currentClient);
    }
}

function renderDevices(clients) {
    const list = getEl('deviceList');
    if (!list) return;

    const valid = clients.filter((c) => c.ClientName);

    if (!valid.length) {
        deviceEls.forEach((el) => io?.unobserve(el));
        deviceEls.clear();
        clientCanvases.clear();
        visibleKeys.clear();
        if (!getEl('noDevices')) {
            list.innerHTML = `
                <div class="no-devices" id="noDevices">
                    <svg style="width: 36px; height: 36px; margin-bottom: 10px; opacity: 0.4; fill: currentColor;" viewBox="0 0 24 24">
                        <path d="M21 2H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h7v2H8v2h8v-2h-2v-2h7c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H3V4h18v12z"/>
                    </svg>
                    <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">Waiting for connected PCs…</div>
                    <div style="font-size: 12px; opacity: 0.7;">Client stations will appear here once they connect to the network.</div>
                </div>
            `;
        }
        organizeDevices();
        return;
    }

    getEl('noDevices')?.remove();

    const seen = new Set();

    valid.forEach((item) => {
        const name = item.ClientName;
        const key = name.toUpperCase();
        seen.add(key);

        let el = deviceEls.get(key);

        if (!el) {
            // New client -> create the card once
            const act = clientActivityMap.get(key);
            const status = act ? (act.windowTitle || act.appName) : 'Idle / Online';

            el = document.createElement('div');
            el.dataset.name = name;
            el.innerHTML = `
                <div class="device-top">
                    <div class="device-avatar-wrap"><div class="avatar">${escapeHtml(name).toUpperCase()}</div></div>
                    <div class="status-badge"><span class="activity-dot"></span>Active</div>
                </div>
                <div class="screen-preview-container">
                    <canvas id="canvas-${key}"></canvas>
                </div>
                <div class="device-body">
                    <div class="device-body-label">Activity</div>
                    <div class="device-sub" id="sub-${key}">${escapeHtml(status)}</div>
                </div>`;

            el.addEventListener('click', (e) => {
                e.stopPropagation();
                selectDevice(name);
            });

            list.appendChild(el);
            deviceEls.set(key, el);

            // Register canvas context for real-time updating
            clientCanvases.set(key, el.querySelector('canvas').getContext('2d', { alpha: false }));
            io?.observe(el); // lets us pause video for cards that are off-screen
        }

        el.className = `device-entry ${currentClient === key ? 'active' : ''}`;
    });

    // Remove cards for clients that are gone
    [...deviceEls.keys()].forEach((key) => {
        if (seen.has(key)) return;
        io?.unobserve(deviceEls.get(key));
        deviceEls.get(key).remove();
        visibleKeys.delete(key);
        deviceEls.delete(key);
        clientCanvases.delete(key);
    });

    organizeDevices();
    updateThumbTarget();
}

// Sort cards by name, apply the search filter and refresh the counter.
// Cards are only moved when the order actually changed, so canvases are never rebuilt.
function organizeDevices() {
    const list = getEl('deviceList');
    if (!list) return;

    const dir = sortDir === 'desc' ? -1 : 1;
    const cards = [...deviceEls.values()]
        .sort((a, b) => dir * collator.compare(a.dataset.name, b.dataset.name));

    const current = [...list.querySelectorAll(':scope > .device-entry')];
    if (cards.length !== current.length || cards.some((c, i) => c !== current[i])) {
        cards.forEach((c) => list.appendChild(c));
    }

    let visible = 0;
    cards.forEach((c) => {
        const sub = getEl(`sub-${c.dataset.name.toUpperCase()}`)?.textContent || '';
        const show = !filterText || `${c.dataset.name} ${sub}`.toLowerCase().includes(filterText);
        c.classList.toggle('is-hidden', !show);
        if (show) visible++;
    });

    const total = cards.length;
    const countEl = getEl('deviceCount');
    if (countEl) countEl.textContent = filterText ? `${visible} / ${total}` : `${total} online`;

    // "no match" message while searching
    let nm = getEl('noMatch');
    if (total && !visible) {
        if (!nm) {
            nm = document.createElement('div');
            nm.id = 'noMatch';
            nm.className = 'no-devices';
            nm.textContent = 'No PC matches your search.';
            list.appendChild(nm);
        }
    } else {
        nm?.remove();
    }
}

function setSort(dir) {
    sortDir = dir;
    const label = getEl('sortLabel');
    if (label) label.textContent = dir === 'desc' ? 'Z → A' : 'A → Z';
    organizeDevices();
}
function selectDevice(name) {
    currentClient = name ? name.toUpperCase() : '';

    document.querySelectorAll('.device-entry').forEach((el) => {
        el.classList.toggle('active', el.dataset.name.toUpperCase() === currentClient);
    });

    getEl('detailsSidebar')?.classList.add('visible');
    getEl('sidebarBackdrop')?.classList.add('visible');

    const launchBtn = getEl('remoteLaunchBtn');
    if (launchBtn) {
        launchBtn.href = `Remote.html?client=${encodeURIComponent(currentClient)}`;
    }

    const combinedData = Object.assign(
        {},
        clientDataMap.get(currentClient),
        clientActivityMap.get(currentClient)
    );

    updateInfo(combinedData);
}

function deselectDevice() {
    currentClient = '';
    getEl('detailsSidebar')?.classList.remove('visible');
    getEl('sidebarBackdrop')?.classList.remove('visible');
    document.querySelectorAll('.device-entry').forEach((el) => el.classList.remove('active'));
}

function escapeHtml(str) {
    return str ? String(str).replace(/[&<>]/g, (s) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[s])) : '';
}

document.addEventListener('DOMContentLoaded', () => {
    getEl('sortBtn')?.addEventListener('click', () => setSort(sortDir === 'asc' ? 'desc' : 'asc'));
    getEl('deviceSearch')?.addEventListener('input', (e) => {
        filterText = e.target.value.trim().toLowerCase();
        organizeDevices();
    });
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape') deselectDevice(); });
    connectWebSocket();
});