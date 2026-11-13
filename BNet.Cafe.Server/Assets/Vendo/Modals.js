let totalAmount = 0;
let pendingDigits = "";
let modalCloseTimer = null;
let modalCountdownInterval = null;
let remainingSeconds = 5;

const CHANGER_COIN_VALUE = 5;
const CHANGER_ACK_TIMEOUT_MS = 6000;
let changerDispensing = false;
let changerTotal = 0;
let changerAckTimer = null;
let changerCloseTimer = null;
let changerHadError = false;
const CHANGER_MIN_DISPENSE = 10;
let changerKept = 0;
const CHANGER_ERROR_CLOSE_MS = 6000;
const CHANGER_HOPPER_ERROR_CLOSE_MS = 10000;
const CHANGER_ERROR_COLOR = '#ff3b30';

const numberModal = document.getElementById('numberModal');
const modalNumberDisplay = document.getElementById('modalNumberDisplay');
const modalTimerText = document.getElementById('modalTimerText');
const modalPcTarget = document.getElementById('modalPcTarget');

const warningModal = document.getElementById('warningModal');
const warningModalTimerText = document.getElementById('warningModalTimerText');
let warningCloseTimer = null;
let warningCountdownInterval = null;
let warningRemainingSeconds = 5;

// Report the kiosk's number modal open/closed state so client PCs can lock their Insert Coin button.
// Observing the class covers every open/close path (typing, timeout, force credit, bill changer).
if (numberModal) {
    new MutationObserver(function () {
        if (typeof sendKioskBusy === 'function') {
            const visible = numberModal.classList.contains('visible');
            let target = '';
            if (visible && !isBillChangerActive()) {
                const t = document.querySelector('.psp-card.active .pc-title');
                target = t ? t.innerText.trim() : '';
            }
            sendKioskBusy(visible, false, target);
        }
    }).observe(numberModal, { attributes: true, attributeFilter: ['class'] });
}

function setModalErrorStyle(isError) {
    const color = isError ? CHANGER_ERROR_COLOR : '';
    modalTimerText.style.color = color;
    modalNumberDisplay.style.color = color;
}

function isModalOpen() {
    return (numberModal && numberModal.classList.contains('visible')) || isWarningModalOpen();
}

function showNumberModal(pcName) {
    cancelIdleLock();
    modalPcTarget.innerText = pcName || "PC-01";
    numberModal.classList.add('visible');
}

function hideNumberModal(syncArduinoStateCb) {
    if (changerDispensing) return;

    const insertedAmount = parseInt(modalNumberDisplay.innerText, 10) || 0;
    const activeCard = document.querySelector('.psp-card.active');

    if (activeCard && insertedAmount > 0) {
        const t = activeCard.querySelector('.pc-title');
        const name = t ? t.innerText : "";
        if (activeCard.classList.contains('status-coin-changer') || name === "Bill Changer") {
            startChangerDispense(insertedAmount);
            return;
        }
    }

    numberModal.classList.remove('visible');
    if (modalCloseTimer) clearTimeout(modalCloseTimer);
    if (modalCountdownInterval) clearInterval(modalCountdownInterval);

    if (activeCard) {
        const titleEl = activeCard.querySelector('.pc-title');
        const computerName = titleEl ? titleEl.innerText : "PC-01";
        const isBillChangerCard = activeCard.classList.contains('status-coin-changer') || computerName === "Bill Changer";

        if (isBillChangerCard) {
            if (insertedAmount <= 0) {
                logKioskEvent("Bill Changer closed with no amount inserted.", "0", false, "CHANGER");
            }
        } else {
            if (insertedAmount > 0) {
                const amountField = document.querySelector('[id$="HiddenField_ModalAmount"]');
                const nameField = document.querySelector('[id$="HiddenField_ModalComputerName"]');
                const triggerBtn = document.querySelector('[id$="LinkButton_ProcessVendo"]');

                if (amountField) amountField.value = insertedAmount;
                if (nameField) nameField.value = computerName;
                if (triggerBtn) triggerBtn.click();
            }
        }
    }

    totalAmount = 0;
    pendingDigits = "";
    if (syncArduinoStateCb) syncArduinoStateCb();
}

function isBillChangerActive() {
    const activeCard = document.querySelector('.psp-card.active');
    if (!activeCard) return false;
    const t = activeCard.querySelector('.pc-title');
    const name = t ? t.innerText : "";
    return activeCard.classList.contains('status-coin-changer') || name === "Bill Changer";
}

function resetModalCloseTimer(syncArduinoStateCb) {
    if (modalCloseTimer) clearTimeout(modalCloseTimer);
    if (modalCountdownInterval) clearInterval(modalCountdownInterval);

    var isBillChanger = isBillChangerActive();

    const configInsertTimer = (typeof kioskConfig !== 'undefined' && kioskConfig.insertBillTimer) ? kioskConfig.insertBillTimer : 5;

    // Use configInsertTimer for both or separate them if needed
    const closeSeconds = configInsertTimer;
    remainingSeconds = closeSeconds;
    setModalErrorStyle(false);

    modalTimerText.innerText = isBillChanger ? `Dispensing in ${remainingSeconds}s` : `Closing in ${remainingSeconds}s`;

    modalCountdownInterval = setInterval(() => {
        remainingSeconds--;
        if (remainingSeconds > 0) {
            modalTimerText.innerText = isBillChanger ? `Dispensing in ${remainingSeconds}s` : `Closing in ${remainingSeconds}s`;
        } else {
            modalTimerText.innerText = `Closing...`;
        }
    }, 1000);

    modalCloseTimer = setTimeout(() => {
        hideNumberModal(syncArduinoStateCb);
    }, closeSeconds * 1000);
}

function handleNumberInput(amount, currentPcName) {
    if (changerDispensing) return;
    playCoinSound();
    totalAmount += parseInt(amount, 10) || 0;
    modalNumberDisplay.innerText = totalAmount;
    showNumberModal(currentPcName);
    resetModalCloseTimer();

    // Show the running amount on the client PC's Insert Coin window.
    if (typeof reportInsertedAmount === 'function') reportInsertedAmount(currentPcName, totalAmount);
}

function handleEnterInput(syncArduinoStateCb) {
    if (changerDispensing) return;
    modalNumberDisplay.innerText = totalAmount;
    cancelIdleLock();
    resetModalCloseTimer(syncArduinoStateCb);
}

function startChangerDispense(amount) {
    const belowMin = amount < CHANGER_MIN_DISPENSE;
    const coins = belowMin ? 0 : Math.floor(amount / CHANGER_COIN_VALUE);
    const payout = coins * CHANGER_COIN_VALUE;
    changerKept = amount - payout;

    changerDispensing = true;
    changerHadError = false;
    changerTotal = payout;

    if (modalCloseTimer) clearTimeout(modalCloseTimer);
    if (modalCountdownInterval) clearInterval(modalCountdownInterval);
    if (changerCloseTimer) { clearTimeout(changerCloseTimer); changerCloseTimer = null; }

    totalAmount = 0;
    pendingDigits = "";
    if (coins === 0) {
        modalNumberDisplay.innerText = amount;
        logKioskEvent(`Bill Changer Error: Insufficient amount (below ₱${CHANGER_MIN_DISPENSE}).`, amount.toString(), false, "CHANGER");
        finishChangerDispense(`Insufficient amount (below ${PESO}${CHANGER_MIN_DISPENSE}). Not dispensed – contact admin.`, true, CHANGER_HOPPER_ERROR_CLOSE_MS);
        return;
    }

    modalNumberDisplay.innerText = payout;
    modalTimerText.innerText = 'Dispensing change...';
    setModalErrorStyle(false);
    armChangerAckTimer();
    sendSerialCommand('D' + payout + '\n');
}

function armChangerAckTimer() {
    if (changerAckTimer) clearTimeout(changerAckTimer);
    changerAckTimer = setTimeout(() => {
        logKioskEvent("Bill Changer Error: No response from change dispenser", changerTotal.toString(), false, "CHANGER");
        finishChangerDispense('No response from change dispenser', true);
    }, CHANGER_ACK_TIMEOUT_MS);
}

function setChangerRemaining(value) {
    modalNumberDisplay.innerText = Math.max(0, value);
}

function finishChangerDispense(message, isError, closeMs) {
    if (changerCloseTimer) return;
    if (changerAckTimer) { clearTimeout(changerAckTimer); changerAckTimer = null; }

    if (!isError) setChangerRemaining(0);
    modalTimerText.innerText = message || 'Change complete';
    setModalErrorStyle(!!isError);

    const delay = closeMs || (isError ? CHANGER_ERROR_CLOSE_MS : 1500);
    changerCloseTimer = setTimeout(() => {
        changerCloseTimer = null;
        changerDispensing = false;
        modalNumberDisplay.innerText = '0';
        setModalErrorStyle(false);
        hideNumberModal();
    }, delay);
}

function handleArduinoLine(line) {
    console.log('[Arduino]', line);
    if (!changerDispensing) return;
    armChangerAckTimer();

    let m;
    if ((m = line.match(/^Hopper Coin (\d+)/))) {
        setChangerRemaining(changerTotal - parseInt(m[1], 10) * CHANGER_COIN_VALUE);
    } else if (/dispense rejected: LOCKED/i.test(line)) {
        finishChangerDispense('Dispenser is locked', true);
    } else if (/^Invalid amount/i.test(line)) {
        finishChangerDispense('Invalid amount', true);
    } else if (/^STOP: DONE/i.test(line)) {
        if (changerKept > 0) {
            setChangerRemaining(0);
            finishChangerDispense(`Insufficient amount. ${PESO}${changerKept} kept`, true, CHANGER_ERROR_CLOSE_MS);
        } else {
            finishChangerDispense('Change complete', false);
        }
    } else if (/^STOP: /i.test(line)) {
        changerHadError = true;
    } else if (changerHadError && (m = line.match(/Coins out\s*:\s*(\d+)/))) {
        const remaining = Math.max(0, changerTotal - parseInt(m[1], 10) * CHANGER_COIN_VALUE);
        setChangerRemaining(remaining);
        const msg = remaining > 0 ? `Not enough coins. ${PESO}${remaining} not dispensed` : 'Hopper empty or jammed';
        finishChangerDispense(msg, true, CHANGER_HOPPER_ERROR_CLOSE_MS);
    }
}

function isWarningModalOpen() {
    return warningModal && warningModal.classList.contains('visible');
}

function showWarningModal() {
    if (isWarningModalOpen()) return;
    cancelIdleLock();
    if (warningModal) warningModal.classList.add('visible');
    logKioskEvent(`Anti Static Ignition Detection triggered`, "0", false, "ACCEPTOR");
}

function hideWarningModal() {
    if (warningModal) warningModal.classList.remove('visible');
    if (warningCloseTimer) clearTimeout(warningCloseTimer);
    if (warningCountdownInterval) clearInterval(warningCountdownInterval);
}

function forceProcessCreditOnKiosk(clientName) {
    if (!insertCoinTargetClient || !sameClientName(insertCoinTargetClient, clientName)) return;

    if (modalCloseTimer) clearTimeout(modalCloseTimer);
    if (modalCountdownInterval) clearInterval(modalCountdownInterval);

    const insertedAmount = parseInt(modalNumberDisplay.innerText, 10) || 0;
    if (insertedAmount > 0) {
        const activeCard = document.querySelector('.psp-card.active');
        if (activeCard) {
            const t = activeCard.querySelector('.pc-title');
            const computerName = t ? t.innerText : clientName;

            const amountField = document.querySelector('[id$="HiddenField_ModalAmount"]');
            const nameField = document.querySelector('[id$="HiddenField_ModalComputerName"]');
            const triggerBtn = document.querySelector('[id$="LinkButton_ProcessVendo"]');

            if (amountField) amountField.value = insertedAmount;
            if (nameField) nameField.value = computerName;
            if (triggerBtn) triggerBtn.click();
        }
    }
    hideNumberModal();
}