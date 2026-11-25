(function () {
    const CHANNEL_NAME = 'bnet_vendo_single_tab_channel';
    const TAB_ID = 'tab_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8);

    // 'close_old' = new tab takes over, old tab locks, releases serial port, and tries to close/block
    // 'block_new' = existing tab stays active, new tab is blocked and cannot use serial port
    const TAB_GUARD_MODE = 'close_old';

    let isBlockedByGuard = false;
    let channel = null;

    function renderTabBlockOverlay(titleText, subText) {
        let el = document.getElementById('singleTabGuardOverlay');
        if (!el) {
            el = document.createElement('div');
            el.id = 'singleTabGuardOverlay';
            Object.assign(el.style, {
                position: 'fixed',
                inset: '0',
                width: '100vw',
                height: '100vh',
                backgroundColor: '#090d16',
                color: '#f8fafc',
                zIndex: '2147483647',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                textAlign: 'center',
                padding: '24px',
                fontFamily: "'Segoe UI', system-ui, sans-serif"
            });
            document.body.appendChild(el);
        }

        const safeTitle = typeof escapeHtml === 'function' ? escapeHtml(titleText) : titleText;
        const safeSub = typeof escapeHtml === 'function' ? escapeHtml(subText) : subText;

        el.innerHTML = `
            <div style="font-size: 3.5rem; margin-bottom: 14px;">🔒</div>
            <h1 style="font-size: 1.8rem; margin: 0 0 10px 0; color: #ff3b30;">${safeTitle}</h1>
            <p style="font-size: 1.1rem; max-width: 520px; color: #cbd5e1; margin: 0;">${safeSub}</p>
        `;
        el.style.display = 'flex';
    }

    function takeOverThisTab() {
        isBlockedByGuard = false;
        const existing = document.getElementById('singleTabGuardOverlay');
        if (existing) existing.style.display = 'none';
    }

    function deactivateThisTab(reasonTitle, reasonSub) {
        if (isBlockedByGuard) return;
        isBlockedByGuard = true;

        try {
            if (typeof forceLockSystem === 'function' && typeof sendSerialCommand === 'function') {
                forceLockSystem(sendSerialCommand);
            }
        } catch (e) { }

        const doRelease = () => {
            if (typeof releaseSerialPort === 'function') {
                releaseSerialPort();
            }
        };

        if (typeof serialQueue !== 'undefined' && serialQueue && typeof serialQueue.then === 'function') {
            serialQueue.then(doRelease, doRelease);
        } else {
            setTimeout(doRelease, 150);
        }

        renderTabBlockOverlay(reasonTitle, reasonSub);

        setTimeout(() => {
            try { window.opener = null; } catch (e) { }
            try { window.close(); } catch (e) { }
        }, 100);
    }

    const originalSendSerialCommand = window.sendSerialCommand;
    if (typeof originalSendSerialCommand === 'function') {
        window.sendSerialCommand = function (command) {
            if (isBlockedByGuard) return;
            return originalSendSerialCommand.apply(this, arguments);
        };
    }

    const originalOpenSerial = window.openSerial;
    if (typeof originalOpenSerial === 'function') {
        window.openSerial = async function () {
            if (isBlockedByGuard) return false;
            return originalOpenSerial.apply(this, arguments);
        };
    }

    if ('BroadcastChannel' in window) {
        channel = new BroadcastChannel(CHANNEL_NAME);

        channel.onmessage = (event) => {
            const msg = event.data || {};
            if (!msg.senderId || msg.senderId === TAB_ID) return;

            if (msg.type === 'NEW_TAB_OPENED') {
                if (TAB_GUARD_MODE === 'close_old') {
                    deactivateThisTab(
                        'Session Moved to Another Tab',
                        'This Vendo Machine page was opened in a newer tab. This tab has been locked and disconnected from the serial port.'
                    );
                } else if (TAB_GUARD_MODE === 'block_new' && !isBlockedByGuard) {
                    channel.postMessage({ type: 'TAB_ACTIVE', senderId: TAB_ID });
                }
            } else if (msg.type === 'TAB_ACTIVE') {
                if (TAB_GUARD_MODE === 'block_new') {
                    deactivateThisTab(
                        'Already Open in Another Tab',
                        'BNet Vendo Machine is already active in another browser tab. Please use that tab.'
                    );
                }
            }
        };

        window.addEventListener('load', () => {
            channel.postMessage({ type: 'NEW_TAB_OPENED', senderId: TAB_ID });
        });

        window.addEventListener('beforeunload', () => {
            try {
                channel.postMessage({ type: 'TAB_CLOSING', senderId: TAB_ID });
            } catch (e) { }
        });
    } else {
        const STORAGE_KEY = 'bnet_vendo_active_tab';
        localStorage.setItem(STORAGE_KEY, JSON.stringify({ id: TAB_ID, ts: Date.now() }));

        window.addEventListener('storage', (e) => {
            if (e.key !== STORAGE_KEY || !e.newValue) return;
            try {
                const info = JSON.parse(e.newValue);
                if (info.id && info.id !== TAB_ID) {
                    if (TAB_GUARD_MODE === 'close_old') {
                        deactivateThisTab(
                            'Session Moved to Another Tab',
                            'Opened in another tab. This tab has been locked and disconnected from the serial port.'
                        );
                    } else if (TAB_GUARD_MODE === 'block_new' && !isBlockedByGuard) {
                        deactivateThisTab(
                            'Already Open in Another Tab',
                            'BNet Vendo Machine is already running in another tab.'
                        );
                    }
                }
            } catch (err) { }
        });
    }

    window.BNetTabGuard = {
        isBlocked: () => isBlockedByGuard,
        takeOver: takeOverThisTab
    };
})();