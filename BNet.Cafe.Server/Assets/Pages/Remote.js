'use strict';
let currentClient = '';
const clientDataMap = new Map();
const clientActivityMap = new Map();
const clientCanvases = new Map(); // key -> 2D context of the card canvas
const thumbStreams = new Map();   // key -> { ws, pending, last, busy, retry, closed }
const textDecoder = new TextDecoder('utf-8');
const textEncoder = new TextEncoder();
let ws = null;
let wsReady = false;

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
    ws = new WebSocket(`ws://${window.location.hostname}:2050/ws/browser`);
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

    ws.onclose = () => {
        wsReady = false;
        setTimeout(connectWebSocket, 3000);
    };
}

// ---------------------------------------------------------------------------
// Per-client thumbnail streams (one socket per card, same method as Remote.html)
// ---------------------------------------------------------------------------

// Remote.html strips the first space from the client name, so do the same here
const thumbSubKey = (key) => `screen_1_${key.replace(' ', '')}`;

function openThumbStream(key) {
    if (thumbStreams.has(key)) return;
    const s = { ws: null, pending: null, last: null, busy: false, retry: null, closed: false };
    thumbStreams.set(key, s);

    const connect = () => {
        if (s.closed) return;
        const sock = new WebSocket(`ws://${window.location.hostname}:2050/ws/browser`);
        sock.binaryType = 'arraybuffer';
        s.ws = sock;

        sock.onopen = () => {
            const kb = textEncoder.encode(thumbSubKey(key));
            const msg = new Uint8Array(1 + kb.length);
            msg[0] = 0x21; // Subscription header flag
            msg.set(kb, 1);
            sock.send(msg.buffer);
        };

        sock.onmessage = (e) => {
            if (!(e.data instanceof ArrayBuffer) || !e.data.byteLength) return;
            if (new Uint8Array(e.data, 0, 1)[0] !== 0x10) return; // ignore 0x11 / 0x12 here
            s.pending = e.data; // keep only the latest frame
            s.last = e.data;    // cache so the card can be repainted after a re-render
            drawThumb(key);
        };

        sock.onclose = () => {
            if (!s.closed) s.retry = setTimeout(connect, 3000);
        };
    };
    connect();
}

function closeThumbStream(key) {
    const s = thumbStreams.get(key);
    if (!s) return;
    s.closed = true;
    clearTimeout(s.retry);
    try { s.ws?.close(); } catch { }
    thumbStreams.delete(key);
}

function syncThumbStreams(keys) {
    const wanted = new Set(keys);
    [...thumbStreams.keys()].forEach((k) => { if (!wanted.has(k)) closeThumbStream(k); });
    keys.forEach(openThumbStream);
}

function drawThumb(key) {
    const s = thumbStreams.get(key);
    if (!s || s.busy || !s.pending || !clientCanvases.has(key)) return;

    const buf = s.pending;
    s.pending = null;
    s.busy = true;

    createImageBitmap(new Blob([new Uint8Array(buf, 1)], { type: 'image/jpeg' }))
        .then((bm) => {
            const ctx = clientCanvases.get(key); // look up again in case the list re-rendered
            if (ctx) {
                const c = ctx.canvas;
                if (c.width !== bm.width || c.height !== bm.height) {
                    c.width = bm.width;
                    c.height = bm.height;
                }
                ctx.drawImage(bm, 0, 0);
            }
            bm.close();
        })
        .catch(() => { })
        .finally(() => {
            s.busy = false;
            if (s.pending) drawThumb(key);
        });
}

// ---------------------------------------------------------------------------
// Client list / activity handlers
// ---------------------------------------------------------------------------
function handleClientListUpdate(clients) {
    clientDataMap.clear();
    clients.forEach((c) => {
        if (c.ClientName) clientDataMap.set(c.ClientName.toUpperCase(), c);
    });

    renderDevices(clients); // rebuilds canvases first
    syncThumbStreams([...clientDataMap.keys()]);

    // Repaint the last frame so cards don't flash blank after a re-render
    thumbStreams.forEach((s, key) => {
        if (s.last) {
            s.pending = s.last;
            drawThumb(key);
        }
    });

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

    if (currentClient === accountKey) {
        selectDevice(currentClient);
    }
}

function renderDevices(clients) {
    const list = getEl('deviceList');
    if (!list) return;
    list.innerHTML = '';
    clientCanvases.clear();

    if (!clients.length) {
        list.innerHTML = `
            <div class="no-devices" id="noDevices">
                <svg style="width: 36px; height: 36px; margin-bottom: 10px; opacity: 0.4; fill: currentColor;" viewBox="0 0 24 24">
                    <path d="M21 2H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h7v2H8v2h8v-2h-2v-2h7c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H3V4h18v12z"/>
                </svg>
                <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">Waiting for connected PCs…</div>
                <div style="font-size: 12px; opacity: 0.7;">Client stations will appear here once they connect to the network.</div>
            </div>
        `;
        return;
    }

    clients.forEach((item) => {
        const name = item.ClientName;
        if (!name) return;
        const key = name.toUpperCase();
        const act = clientActivityMap.get(key);
        const status = act ? (act.windowTitle || act.appName) : 'Idle / Online';

        const el = document.createElement('div');
        el.className = `device-entry ${currentClient === key ? 'active' : ''}`;
        el.dataset.name = name;
        el.innerHTML = `
            <div class="device-top">
                <div class="device-avatar-wrap"><div class="avatar">${escapeHtml(name).toUpperCase()}</div></div>
                <div class="status-badge"><span class="activity-dot"></span>Active</div>
            </div>
            <div class="screen-preview-container" style="background:#000; width:100%; height:120px; overflow:hidden; display:flex; align-items:center; justify-content:center; border-radius:4px; margin:8px 0;">
                <canvas id="canvas-${key}" style="max-width:100%; max-height:100%; object-fit:contain;"></canvas>
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

        // Register canvas context for real-time updating
        const canvasEl = document.getElementById(`canvas-${key}`);
        if (canvasEl) {
            clientCanvases.set(key, canvasEl.getContext('2d', { alpha: false }));
        }
    });
}

function selectDevice(name) {
    currentClient = name ? name.toUpperCase() : '';

    document.querySelectorAll('.device-entry').forEach((el) => {
        el.classList.toggle('active', el.dataset.name.toUpperCase() === currentClient);
    });

    getEl('detailsSidebar')?.classList.add('visible');

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
    document.querySelectorAll('.device-entry').forEach((el) => el.classList.remove('active'));
}

function escapeHtml(str) {
    return str ? String(str).replace(/[&<>]/g, (s) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[s])) : '';
}

document.addEventListener('DOMContentLoaded', () => {
    connectWebSocket();
});