let kioskConfig = {
    screenLockTimer: 15,
    insertBillTimer: 5,
    kioskIdleTimer: 10,
    kioskType: "WITH MONITOR"
};

async function fetchClientConfig() {
    try {
        var endpoint = /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/GetClientConfigHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/GetClientConfigHandler.ashx');

        const response = await fetch(endpoint, { cache: 'no-store' });
        const data = await response.json();

        if (data) {
            kioskConfig = {
                screenLockTimer: data.kioskScreenLockTimer ?? 15,
                insertBillTimer: data.kioskInsertBillTimer ?? 5,
                kioskIdleTimer: data.kioskIdleTimer ?? 10,
                kioskType: data.kioskType || "WITH MONITOR"
            };
        }
    } catch (err) {
        console.error('Failed to fetch client config:', err);
    }
}

let clientData = [];

async function fetchClientData() {
    try {
        var endpoint = /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/GetComputerHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/GetComputerHandler.ashx');

        const response = await fetch(endpoint);
        const data = await response.json();

        if (Array.isArray(data)) {
            if (JSON.stringify(data) !== JSON.stringify(clientData)) {
                clientData = data;
                renderPSPMenu(clientData);
                renderAttractGrid(clientData);
                syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen);
            }
        }
    } catch (err) {
        console.error('Failed to fetch computer data:', err);
    }
}

// Bind Global Input Events
['mousedown', 'keydown', 'touchstart', 'wheel', 'click'].forEach(event => {
    window.addEventListener(event, () => resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition), { passive: true });
});
function buildSseUrl() {
    const { protocol, hostname, host } = window.location;
    const isLocalOrIp = hostname === 'localhost'
        || /^\d{1,3}(\.\d{1,3}){3}$/.test(hostname)
        || hostname.startsWith('[');
    return protocol + '//' + (isLocalOrIp ? hostname + ':2050' : host) + '/sse';
}

// ---------------------------------------------------------------------------
// Keyboard focus helper
// A page can only receive key presses when its OS window is the foreground
// window AND the document itself has focus. On a fresh launch (especially on
// another PC) neither is guaranteed, so keep asking for focus until we get it.
// (The OS-level part is handled by kiosk-mode.ps1; this is the page-level part.)
// ---------------------------------------------------------------------------
function grabKeyboardFocus() {
    try { window.focus(); } catch (e) { }
    const ae = document.activeElement;
    const nothingFocused = !ae || ae === document.body || ae === document.documentElement;
    if (nothingFocused && document.body) {
        if (!document.body.hasAttribute('tabindex')) document.body.setAttribute('tabindex', '-1');
        try { document.body.focus({ preventScroll: true }); } catch (e) { }
    }
}

function ensureKeyboardFocus() {
    grabKeyboardFocus();
    let attempts = 0;
    const timer = setInterval(() => {
        attempts++;
        if (document.hasFocus() || attempts > 60) { // stop once focused, or after ~30 s
            clearInterval(timer);
            return;
        }
        grabKeyboardFocus();
    }, 500);
}

window.addEventListener('focus', grabKeyboardFocus);

window.addEventListener('load', function () {
    ensureKeyboardFocus();
    const endpoint = buildSseUrl();
    try {
        const evtSource = new EventSource(endpoint);
        evtSource.onmessage = function () {
            fetchClientData();
            const LinkButton_Refresh = document.querySelector('[id$="LinkButton_Refresh"]');
            if (LinkButton_Refresh) LinkButton_Refresh.click();
        };
    } catch (e) {
        console.error('Failed to initialize SSE:', e);
    }
    resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition);
    showPressAnyKey();
    fetchClientConfig();
});

syncServerTime();
setInterval(syncServerTime, 5 * 60 * 1000);
discoverImages();
fetchClientData();
initCarouselEvents(() => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));


//mouse clicks and touch taps on the lock screen
document.getElementById('pressAnyKeyScreen').addEventListener('pointerdown', (e) => {
    if (e.target.closest('.trial-activation-btn, #licenseModal')) return;
    if (isPressAnyKeyVisible()) {
        e.preventDefault();
        serialTask(async () => {
            if (await openSerial(true)) {
                hidePressAnyKey(() => updateCarouselPosition(0), () => resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition));
                await serialWriter.write(new TextEncoder().encode('U'));
            }
        });
    }
});
// Keydown listeners
document.addEventListener('keydown', (e) => {
    // Check if the license modal or its inputs are currently active/focused
    const licenseModal = document.getElementById('licenseModal');
    const isLicenseModalVisible = licenseModal && !licenseModal.classList.contains('d-none') && licenseModal.style.display !== 'none';
    const activeElement = document.activeElement;
    const isEditingLicense = activeElement && (
        activeElement.id === 'TextBox_ServerSerial' ||
        activeElement.id === 'TextBox_LicenseKey' ||
        activeElement.closest('#licenseModal')
    );

    // Allow normal copy (Ctrl+C), paste (Ctrl+V), select all (Ctrl+A), and typing when inside the license modal
    if (isLicenseModalVisible && isEditingLicense) {
        if (e.ctrlKey && ['c', 'v', 'a', 'x'].includes(e.key.toLowerCase())) {
            return; // Let the browser handle native copy/paste/select-all
        }
        // Allow regular typing inside the license inputs
        return;
    }

    if (isPressAnyKeyVisible()) {
        if (['arrowleft', 'arrowright', 'z', 'x'].includes(e.key.toLowerCase()) || (e.ctrlKey && ['a', 'c'].includes(e.key.toLowerCase()))) {
            e.preventDefault();
            serialTask(async () => {
                if (await openSerial(true)) {
                    hidePressAnyKey(() => updateCarouselPosition(0), () => resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition));
                    await serialWriter.write(new TextEncoder().encode('U'));
                }
            });
            return;
        }
        e.preventDefault();
        return;
    }

    // Allow coin/bill acceptor numbers (0-9) to pass through so currency inputs work properly
    if (e.key >= '0' && e.key <= '9') {
        if (e.key === '0') {
            e.preventDefault();
            showWarningModal();
            return;
        }
        e.preventDefault();
        const selectedClient = filteredClientData[selectedIndex];
        let currentPcName = selectedClient?.clientName || selectedClient?.ClientName || "PC-01";
        handleNumberInput(e.key, currentPcName);
        return;
    }

    if (e.key === 'Enter' && isModalOpen()) {
        e.preventDefault();
        handleEnterInput(() => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));
        return;
    }

    // Block arrow/navigation keys if the modal or client insert is active
    if (isModalOpen() || (typeof isClientInsertingCoin === 'function' && isClientInsertingCoin())) return;

    const key = e.key.toLowerCase();

    // Block arrow/navigation keys if a client is currently inserting coins
    if (key === 'arrowright' || key === 'x' || (e.ctrlKey && key === 'c')) {
        e.preventDefault();
        if (typeof isClientInsertingCoin === 'function' && isClientInsertingCoin()) return;
        if (selectedIndex < filteredClientData.length - 1) {
            selectedIndex++;
            updateCarouselPosition(0, () => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));
        }
    } else if (key === 'arrowleft' || key === 'z' || (e.ctrlKey && key === 'a')) {
        e.preventDefault();
        if (typeof isClientInsertingCoin === 'function' && isClientInsertingCoin()) return;
        if (selectedIndex > 0) {
            selectedIndex--;
            updateCarouselPosition(0, () => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));
        }
    }
});

window.addEventListener('blur', () => forceLockSystem(sendSerialCommand));
document.addEventListener('visibilitychange', () => {
    if (document.hidden) forceLockSystem(sendSerialCommand);
});