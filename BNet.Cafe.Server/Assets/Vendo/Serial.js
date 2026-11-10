let serialPort = null;
let serialWriter = null;
let serialQueue = Promise.resolve();
let serialReader = null;

function updateBoardStatus(isConnected, portName = "COM9") {
    const indicator = document.getElementById('boardStatusIndicator');
    if (!indicator) return;
    if (isConnected) {
        indicator.className = 'board-status connected';
        indicator.innerText = `BOARD CONNECTED - ${portName}`;
    } else {
        indicator.className = 'board-status disconnected';
        indicator.innerText = 'BOARD DISCONNECTED';
    }
}

async function readSerialLoop(port) {
    if (serialReader || !port.readable) return;
    const decoder = new TextDecoder();
    let buffer = '';
    const reader = port.readable.getReader();
    serialReader = reader;
    try {
        while (true) {
            const { value, done } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });
            let idx;
            while ((idx = buffer.indexOf('\n')) >= 0) {
                const line = buffer.slice(0, idx).replace(/\r$/, '').trim();
                buffer = buffer.slice(idx + 1);
                if (line) {
                    try { handleArduinoLine(line); } catch (e) { console.error(e); }
                }
            }
            if (buffer.length > 4000) buffer = '';
        }
    } catch (e) {
        console.warn('Serial read stopped:', e);
    } finally {
        try { reader.releaseLock(); } catch (e) { }
        serialReader = null;
    }
}

async function openSerial(allowPrompt) {
    if (!('serial' in navigator)) {
        console.error('Web Serial not available.');
        updateBoardStatus(false);
        return false;
    }
    if (serialWriter) {
        updateBoardStatus(true, "COM9");
        return true;
    }

    if (!serialPort) {
        try {
            const ports = await navigator.serial.getPorts();
            serialPort = ports[0] || null;
            if (!serialPort && allowPrompt) {
                serialPort = await navigator.serial.requestPort();
            }
        } catch (err) {
            console.warn('Error getting serial ports:', err);
        }
        if (!serialPort) {
            updateBoardStatus(false);
            return false;
        }
    }

    try {
        if (!serialPort.writable) {
            await serialPort.open({ baudRate: 9600 });
        }
        serialWriter = serialPort.writable.getWriter();
        readSerialLoop(serialPort);
        updateBoardStatus(true, "COM9");
        return true;
    } catch (err) {
        console.error('Failed to open serial port:', err);
        serialPort = null;
        serialWriter = null;
        updateBoardStatus(false);
        if (typeof showPressAnyKey === 'function') {
            showPressAnyKey();
        }
        return false;
    }
}

function serialTask(task) {
    serialQueue = serialQueue.then(async () => {
        try {
            await task();
        } catch (err) {
            console.error('Serial error:', err);
            try { if (serialWriter) serialWriter.releaseLock(); } catch (e) { }
            try { if (serialReader) await serialReader.cancel(); } catch (e) { }
            await new Promise(r => setTimeout(r, 50));
            try { if (serialPort) await serialPort.close(); } catch (e) { }
            serialWriter = null;
            serialPort = null;
            updateBoardStatus(false);
            if (typeof showPressAnyKey === 'function') {
                showPressAnyKey();
            }
        }
    });
}

function sendSerialCommand(command) {
    serialTask(async () => {
        if (await openSerial(false)) {
            await serialWriter.write(new TextEncoder().encode(command));
        }
    });
}

const LOCK_WHILE_MODAL_OPEN = false;
const CHANGER_IGNORES_PC_LOCK = true;

function shouldLock(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen) {
    if (isPressAnyKeyVisible()) return true;
    if (changerDispensing) return true;
    if (LOCK_WHILE_MODAL_OPEN && isModalOpen()) return true;

    if (filteredClientData && filteredClientData.length > 0 && selectedIndex >= 0 && selectedIndex < filteredClientData.length) {
        const selectedClient = filteredClientData[selectedIndex];
        if (selectedClient.isCoinChanger && CHANGER_IGNORES_PC_LOCK) return false;
        const status = getClientStatus(selectedClient);
        if (status === "Offline" || status === "Administrator" || status === "Paused") {
            return true;
        }
    }

    const hasValidPc = clientData.some(c => {
        const st = getClientStatus(c);
        return st === "Available" || st === "Occupied";
    });

    return !hasValidPc;
}

function syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen) {
    sendSerialCommand(shouldLock(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen) ? 'L' : 'U');
}

if ('serial' in navigator) {
    navigator.serial.addEventListener('disconnect', () => {
        serialWriter = null;
        serialPort = null;
        updateBoardStatus(false);
        if (typeof showPressAnyKey === 'function') {
            showPressAnyKey();
        }
    });
    navigator.serial.addEventListener('connect', () => {
        updateBoardStatus(true, "COM9");
        syncArduinoState();
    });
}