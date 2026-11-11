let kioskConfig = {
    screenLockTimer: 15,
    insertBillTimer: 5,
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

window.addEventListener('load', function () {
    const endpoint = window.location.protocol + '//' + window.location.hostname + ':2050/sse';
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

// Keydown listeners
document.addEventListener('keydown', (e) => {
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

    if (e.key >= '0' && e.key <= '9') {
        if (e.key === '0') {
            e.preventDefault();
            showWarningModal();
            return;
        }
        e.preventDefault();
        let currentPcName = filteredClientData[selectedIndex]?.clientName || "PC-01";
        handleNumberInput(e.key, currentPcName);
        return;
    }

    if (e.key === 'Enter' && isModalOpen()) {
        e.preventDefault();
        handleEnterInput(() => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));
        return;
    }

    const key = e.key.toLowerCase();
    if (key === 'arrowright' || key === 'x' || (e.ctrlKey && key === 'c')) {
        e.preventDefault();
        if (selectedIndex < filteredClientData.length - 1) {
            selectedIndex++;
            updateCarouselPosition(0, () => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen));
        }
    } else if (key === 'arrowleft' || key === 'z' || (e.ctrlKey && key === 'a')) {
        e.preventDefault();
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