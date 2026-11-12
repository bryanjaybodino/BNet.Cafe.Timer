let idleTimer = null;
let lockCountdownInterval = null;
let lockRemainingSeconds = 60;
const IDLE_TIMEOUT_MS = 10000;

function resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition) {
    if (idleTimer) { clearTimeout(idleTimer); idleTimer = null; }
    if (lockCountdownInterval) { clearInterval(lockCountdownInterval); lockCountdownInterval = null; }

    const idleFooter = document.getElementById('idleCountdownFooter');
    if (idleFooter) idleFooter.style.display = 'none';

    const psp = document.getElementById('pspContainer');
    const isMainMenuViewable = psp && psp.style.display !== 'none';

    if (isMainMenuViewable && !isModalOpen()) {
        idleTimer = setTimeout(() => {
            if (isModalOpen() || changerDispensing) { cancelIdleLock(); return; }
            startLockCountdown(isModalOpen, changerDispensing);
        }, IDLE_TIMEOUT_MS);
    }
}

function cancelIdleLock() {
    if (idleTimer) { clearTimeout(idleTimer); idleTimer = null; }
    if (lockCountdownInterval) { clearInterval(lockCountdownInterval); lockCountdownInterval = null; }
    const idleFooter = document.getElementById('idleCountdownFooter');
    if (idleFooter) idleFooter.style.display = 'none';
}

function startLockCountdown(isModalOpen, changerDispensing) {
    const idleFooter = document.getElementById('idleCountdownFooter');
    const bannerIcon = document.getElementById('bannerIcon');
    const bannerText = document.getElementById('bannerText');

    // Use the fetched config property directly
    lockRemainingSeconds = (typeof kioskConfig !== 'undefined' && kioskConfig.screenLockTimer) ? kioskConfig.screenLockTimer : 15;

    if (bannerIcon) bannerIcon.className = 'fas fa-lock';
    if (bannerText) bannerText.innerText = `LOCKING IN ${lockRemainingSeconds}s`;
    if (idleFooter) idleFooter.style.display = 'flex';

    speakText("System is Locking soon");

    if (lockCountdownInterval) clearInterval(lockCountdownInterval);

    lockCountdownInterval = setInterval(() => {
        if (isModalOpen() || changerDispensing) { cancelIdleLock(); return; }

        lockRemainingSeconds--;
        if (bannerText) bannerText.innerText = `LOCKING IN ${lockRemainingSeconds}s`;

        if (lockRemainingSeconds <= 0) {
            clearInterval(lockCountdownInterval);
            lockCountdownInterval = null;
            if (idleFooter) idleFooter.style.display = 'none';
            showPressAnyKey();
        }
    }, 1000);
}

function showPressAnyKey() {
    if (idleTimer) clearTimeout(idleTimer);
    if (lockCountdownInterval) clearInterval(lockCountdownInterval);

    const idleFooter = document.getElementById('idleCountdownFooter');
    if (idleFooter) idleFooter.style.display = 'none';

    const screen = document.getElementById('pressAnyKeyScreen');
    if (screen) screen.style.display = 'block';

    const psp = document.getElementById('pspContainer');
    if (psp) psp.style.display = 'none';

    speakText("System is locked now");

    // Kiosk is now locked: close the Insert Coin modal on the client PC.
    if (typeof closeInsertCoinModalOnClient === 'function') closeInsertCoinModalOnClient();
}

function hidePressAnyKey(updateCarouselPosition, resetIdleTimerCb) {
    cancelIdleLock();
    const screen = document.getElementById('pressAnyKeyScreen');
    if (screen) screen.style.display = 'none';

    const psp = document.getElementById('pspContainer');
    if (psp) psp.style.removeProperty('display');

    requestAnimationFrame(() => updateCarouselPosition(0));
    resetIdleTimerCb();
    speakText("Choose PC");
}

function getPressAnyKeyScreen() {
    return document.getElementById('pressAnyKeyScreen');
}

function isPressAnyKeyVisible() {
    const screen = getPressAnyKeyScreen();
    return !!screen && screen.style.display !== 'none';
}

function forceLockSystem(sendSerialCommand) {
    cancelIdleLock();
    if (!isPressAnyKeyVisible()) {
        const screen = document.getElementById('pressAnyKeyScreen');
        if (screen) screen.style.display = 'block';
        const psp = document.getElementById('pspContainer');
        if (psp) psp.style.display = 'none';
    }
    sendSerialCommand('L');

    // Kiosk is now locked: close the Insert Coin modal on the client PC.
    if (typeof closeInsertCoinModalOnClient === 'function') closeInsertCoinModalOnClient();
}

function toggleFullScreen() {
    const icon = document.getElementById('fullscreenIcon');
    if (!document.fullscreenElement && !document.webkitFullscreenElement && !document.msFullscreenElement) {
        const docEl = document.documentElement;
        if (docEl.requestFullscreen) docEl.requestFullscreen();
        else if (docEl.webkitRequestFullscreen) docEl.webkitRequestFullscreen();
        if (icon) { icon.classList.remove('fa-expand'); icon.classList.add('fa-compress'); }
    } else {
        if (document.exitFullscreen) document.exitFullscreen();
        else if (document.webkitExitFullscreen) document.webkitExitFullscreen();
        if (icon) { icon.classList.remove('fa-compress'); icon.classList.add('fa-expand'); }
    }
}