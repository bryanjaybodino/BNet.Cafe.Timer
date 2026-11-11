'use strict';
let currentClient = '';
const clientDataMap = new Map();
const clientActivityMap = new Map();
const clientCanvases = new Map(); // Store card canvas contexts
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

// WebSocket Connection
function connectWebSocket() {
    ws = new WebSocket(`ws://${window.location.hostname}:2050/ws/browser`);
    ws.binaryType = 'arraybuffer';

    ws.onopen = () => {
        wsReady = true;
        // Subscribe to main screen thumbnail feeds for all known connected clients
        clientDataMap.forEach((_, key) => {
            sendSubscribe(`screen_1_${key}`);
        });
    };

    ws.onmessage = (e) => {
        if (!(e.data instanceof ArrayBuffer) || !e.data.byteLength) return;
        const bytes = new Uint8Array(e.data);
        const type = bytes[0];

        // Handle Live Frame Stream Packet (0x10)
        if (type === 0x10) {
            handleThumbnailFrame(e.data);
            return;
        }

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

function sendSubscribe(screenKey) {
    if (!wsReady) return;
    const kb = textEncoder.encode(screenKey);
    const msg = new Uint8Array(1 + kb.length);
    msg[0] = 0x21; // Subscription header flag
    msg.set(kb, 1);
    ws.send(msg.buffer);
}

function handleClientListUpdate(clients) {
    clientDataMap.clear();
    clients.forEach(c => {
        if (c.ClientName) {
            const key = c.ClientName.toUpperCase();
            clientDataMap.set(key, c);
            if (wsReady) {
                sendSubscribe(`screen_1_${key}`);
            }
        }
    });
    renderDevices(clients);

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

// Render individual client frame thumbnail onto its respective card canvas
function handleThumbnailFrame(arrayBuffer) {
    // Assuming the server broadcasts frames wrapped or we map them via active stream subscriptions.
    // If your server prepends client routing metadata or you match by active canvas stream:
    createImageBitmap(new Blob([new Uint8Array(arrayBuffer, 1)], { type: 'image/jpeg' }))
        .then((bm) => {
            // Find target canvas element from active subscriptions or fallback to updating visible canvases
            clientCanvases.forEach((ctx, key) => {
                const canvas = ctx.canvas;
                if (canvas.width !== bm.width || canvas.height !== bm.height) {
                    canvas.width = bm.width;
                    canvas.height = bm.height;
                }
                ctx.drawImage(bm, 0, 0);
            });
            bm.close();
        })
        .catch(() => { });
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

    document.querySelectorAll('.device-entry').forEach(el => {
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
    document.querySelectorAll('.device-entry').forEach(el => el.classList.remove('active'));
}

function escapeHtml(str) {
    return str ? String(str).replace(/[&<>]/g, s => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[s])) : '';
}

document.addEventListener('DOMContentLoaded', () => {
    connectWebSocket();
});