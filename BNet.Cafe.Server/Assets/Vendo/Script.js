// --- 1. PROTECTIONS ---
document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('dragstart', e => e.preventDefault());

// --- IDLE TIMER FOR ATTRACT SCREEN ---
let idleTimer = null;
let lockCountdownInterval = null;
let lockRemainingSeconds = 60;
const IDLE_TIMEOUT_MS = 10000; // 16 seconds of inactivity before countdown starts

function resetIdleTimer() {
    if (idleTimer) {
        clearTimeout(idleTimer);
        idleTimer = null;
    }
    if (lockCountdownInterval) {
        clearInterval(lockCountdownInterval);
        lockCountdownInterval = null;
    }

    // Hide the idle countdown footer while active/interacting
    const idleFooter = document.getElementById('idleCountdownFooter');
    if (idleFooter) {
        idleFooter.style.display = 'none';
    }

    const psp = document.getElementById('pspContainer');
    const isMainMenuViewable = psp && psp.style.display !== 'none';

    if (isMainMenuViewable && !isModalOpen()) {
        idleTimer = setTimeout(() => {
            // Never start the lock countdown while money is being inserted / change is dispensing
            if (isModalOpen() || changerDispensing) { cancelIdleLock(); return; }
            startLockCountdown();
        }, IDLE_TIMEOUT_MS);
    }
}

// Stops the idle timer AND a running "LOCKING IN Xs" countdown, and hides the banner.
function cancelIdleLock() {
    if (idleTimer) { clearTimeout(idleTimer); idleTimer = null; }
    if (lockCountdownInterval) { clearInterval(lockCountdownInterval); lockCountdownInterval = null; }
    const idleFooter = document.getElementById('idleCountdownFooter');
    if (idleFooter) idleFooter.style.display = 'none';
}

function startLockCountdown() {
    const idleFooter = document.getElementById('idleCountdownFooter');
    const bannerIcon = document.getElementById('bannerIcon');
    const bannerText = document.getElementById('bannerText');

    lockRemainingSeconds = 15; // Countdown duration before locking
    if (bannerIcon) bannerIcon.className = 'fas fa-lock';
    if (bannerText) bannerText.innerText = `LOCKING IN ${lockRemainingSeconds}s`;

    // Only reveal the footer when the countdown actually begins
    if (idleFooter) idleFooter.style.display = 'flex';

    speakText("System is Locking soon");

    if (lockCountdownInterval) clearInterval(lockCountdownInterval);

    lockCountdownInterval = setInterval(() => {
        // Coin/bill activity during the countdown -> abort the lock
        if (isModalOpen() || changerDispensing) { cancelIdleLock(); return; }

        lockRemainingSeconds--;
        if (bannerText) bannerText.innerText = `LOCKING IN ${lockRemainingSeconds}s`;

        if (lockRemainingSeconds <= 0) {
            clearInterval(lockCountdownInterval);
            lockCountdownInterval = null;
            if (idleFooter) idleFooter.style.display = 'none';

            // Trigger full lock screen
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
    if (screen) screen.style.display = 'block'; // Show full lock screen

    const psp = document.getElementById('pspContainer');
    if (psp) psp.style.display = 'none';

    // --- ADD SOUND WHEN LOCKED ---
    speakText("System is locked now");

    syncArduinoState();
}

function hidePressAnyKey() {
    const screen = document.getElementById('pressAnyKeyScreen');
    if (screen) screen.style.display = 'none'; // Completely hide lock overlay so mouse/swipe works

    const psp = document.getElementById('pspContainer');
    if (psp) psp.style.removeProperty('display');

    requestAnimationFrame(() => updateCarouselPosition(0));
    syncArduinoState();
    resetIdleTimer();

    // --- ADD SOUND WHEN UNLOCKED ---
    speakText("Choose PC");
}

// Bind meaningful user interaction events (removed 'mousemove' to prevent jitter/constant resets)
['mousedown', 'keydown', 'touchstart', 'wheel', 'click'].forEach(event => {
    window.addEventListener(event, resetIdleTimer, { passive: true });
});

// --- CENTRALIZED KIOSK EVENT LOGGER ---
function logKioskEvent(details, amount, isSuccess, type = "ACCEPTOR") {
    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/LogKioskEventHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/LogKioskEventHandler.ashx');

    var url = endpoint + '?details=' + encodeURIComponent(details) +
        '&amount=' + encodeURIComponent(amount || '0') +
        '&isSuccess=' + encodeURIComponent(isSuccess ? 'TRUE' : 'FALSE') +
        '&type=' + encodeURIComponent(type); // Pass type to handler

    fetch(url, { method: 'GET', cache: 'no-store' })
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                console.warn("Kiosk log response warning:", data.message);
            }
        })
        .catch(err => {
            console.error("Failed to post kiosk log via ASHX:", err);
        });
}

// --- NUMBER TYPING & MODAL LOGIC ---
let totalAmount = 0;          // bills already committed (each bill ends with Enter)
let pendingDigits = "";       // digits of the bill currently being typed by the Arduino
let modalCloseTimer = null;
let modalCountdownInterval = null;
let remainingSeconds = 5;

// --- BILL CHANGER (coin hopper) COUNTDOWN ---
// While the hopper drops coins the modal shows the TOTAL and counts it DOWN to 0.
const CHANGER_COIN_VALUE = 5;          // peso value of ONE hopper coin. Must match COIN_VALUE in the .ino
const CHANGER_ACK_TIMEOUT_MS = 6000;   // no word from the board for this long -> stop waiting
let changerDispensing = false;
let changerTotal = 0;
let changerAckTimer = null;
let changerCloseTimer = null;
let changerHadError = false;
const CHANGER_MIN_DISPENSE = 10;   // below this the changer does not dispense at all
let changerKept = 0;      // pesos the machine keeps (amount that is not a multiple of one hopper coin)
const CHANGER_ERROR_CLOSE_MS = 6000;         // other errors (locked / invalid amount / no response)
const CHANGER_HOPPER_ERROR_CLOSE_MS = 10000; // hopper empty / jammed: stay longer so the customer can read it
const CHANGER_ERROR_COLOR = '#ff3b30';       // red used for error messages and the remaining amount
const PESO = '\u20B1';

function setModalErrorStyle(isError) {
    const color = isError ? CHANGER_ERROR_COLOR : '';
    modalTimerText.style.color = color;
    modalNumberDisplay.style.color = color;
}

const numberModal = document.getElementById('numberModal');
const modalNumberDisplay = document.getElementById('modalNumberDisplay');
const modalTimerText = document.getElementById('modalTimerText');
const modalPcTarget = document.getElementById('modalPcTarget');

function isModalOpen() {
    return numberModal.classList.contains('visible');
}

function showNumberModal(pcName) {
    cancelIdleLock(); // stops idle timer + running lock countdown + hides banner
    modalPcTarget.innerText = pcName || "PC-01";
    numberModal.classList.add('visible');
}

function hideNumberModal() {
    if (changerDispensing) return;   // the change countdown closes the modal itself when it is done

    const insertedAmount = parseInt(modalNumberDisplay.innerText, 10) || 0;
    const activeCard = document.querySelector('.psp-card.active');

    // Bill Changer: do NOT close. Keep the modal open, send D<amount> and count the total down.
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

        // Check if the active card is the Bill Changer
        const isBillChangerCard = activeCard.classList.contains('status-coin-changer') || computerName === "Bill Changer";

        if (isBillChangerCard) {
            // Nothing inserted -> nothing to dispense
            if (insertedAmount <= 0) {
                logKioskEvent("Bill Changer closed with no amount inserted.", "0", false, "CHANGER");
            }
        } else {
            // If coins/bills were inserted for a normal PC, pass data to hidden fields and click the LinkButton
            if (insertedAmount > 0) {
                const amountField = document.querySelector('[id$="HiddenField_ModalAmount"]');
                const nameField = document.querySelector('[id$="HiddenField_ModalComputerName"]');
                const triggerBtn = document.querySelector('[id$="LinkButton_ProcessVendo"]');

                if (amountField) amountField.value = insertedAmount;
                if (nameField) nameField.value = computerName;

                if (triggerBtn) {
                    triggerBtn.click(); // Triggers the C# server-side Click event
                }
            }
        }
    }

    totalAmount = 0;
    pendingDigits = "";
    resetIdleTimer();
}

// Bill Changer (dispenser) closes after 5s; coins/bills for normal PCs keep the default 15s
const MODAL_CLOSE_DEFAULT_SECONDS = 15;
const MODAL_CLOSE_DISPENSER_SECONDS = 5;

function isBillChangerActive() {
    const activeCard = document.querySelector('.psp-card.active');
    if (!activeCard) return false;
    const t = activeCard.querySelector('.pc-title');
    const name = t ? t.innerText : "";
    return activeCard.classList.contains('status-coin-changer') || name === "Bill Changer";
}

function resetModalCloseTimer() {
    if (modalCloseTimer) clearTimeout(modalCloseTimer);
    if (modalCountdownInterval) clearInterval(modalCountdownInterval);

    var isBillChanger = isBillChangerActive();
    const closeSeconds = isBillChanger ? MODAL_CLOSE_DISPENSER_SECONDS : MODAL_CLOSE_DEFAULT_SECONDS;
    remainingSeconds = closeSeconds;
    setModalErrorStyle(false);

    if (isBillChanger) {
        modalTimerText.innerText = `Dispensing in ${remainingSeconds}s`;
    }
    else {
        modalTimerText.innerText = `Closing in ${remainingSeconds}s`;
    }


    modalCountdownInterval = setInterval(() => {
        remainingSeconds--;
        if (remainingSeconds > 0) {
            if (isBillChanger) {
                modalTimerText.innerText = `Dispensing in ${remainingSeconds}s`;
            }
            else {
                modalTimerText.innerText = `Closing in ${remainingSeconds}s`;
            }
        } else {
            modalTimerText.innerText = `Closing...`;
        }
    }, 1000);

    modalCloseTimer = setTimeout(() => {
        hideNumberModal();
    }, closeSeconds * 1000);
}

function handleNumberInput(amount) {
    if (changerDispensing) return;   // change is being dispensed: ignore input keys
    const activeCard = document.querySelector('.psp-card.active');
    let currentPcName = "PC-01";
    if (activeCard) {
        const titleEl = activeCard.querySelector('.pc-title');
        if (titleEl) currentPcName = titleEl.innerText;
    }

    // Play bill insertion sound on every input
    playCoinSound();

    // Increment/Add the incoming amount directly to totalAmount instead of appending text digits
    const numericValue = parseInt(amount, 10) || 0;
    totalAmount += numericValue;

    modalNumberDisplay.innerText = totalAmount;
    showNumberModal(currentPcName);
    resetModalCloseTimer();
}

// Enter = the Arduino finished typing one bill -> add it to the total
function handleEnterInput() {
    if (changerDispensing) return;

    modalNumberDisplay.innerText = totalAmount;
    cancelIdleLock();   // keep lock off after entering
    resetModalCloseTimer();
}

// --- BILL CHANGER: send D<amount>, then count the total down as coins drop ---
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
        // Below the minimum: nothing is dispensed, the customer must ask the admin for it
        modalNumberDisplay.innerText = amount;

        // Log Insufficient Amount Below Minimum
        logKioskEvent(`Bill Changer Error: Insufficient amount (below ₱${CHANGER_MIN_DISPENSE}). Amount ₱${amount} not dispensed - customer needs refund.`, amount.toString(), false, "CHANGER");

        finishChangerDispense(`Insufficient amount (below ${PESO}${CHANGER_MIN_DISPENSE}). Not dispensed - inform the admin to get your ${PESO}${amount} back`, true, CHANGER_HOPPER_ERROR_CLOSE_MS);
        return;
    }

    modalNumberDisplay.innerText = payout;          // start from what will actually be paid out
    modalTimerText.innerText = 'Dispensing change...';
    setModalErrorStyle(false);

    armChangerAckTimer();
    console.log('Bill Changer: sending D' + payout + (changerKept ? ' (kept ' + changerKept + ')' : ''));
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
    if (changerCloseTimer) return;                  // already finishing
    if (changerAckTimer) { clearTimeout(changerAckTimer); changerAckTimer = null; }

    const totalInserted = (parseInt(modalNumberDisplay.innerText, 10) || 0) + (changerKept || 0);

    if (!isError) setChangerRemaining(0);
    modalTimerText.innerText = message || 'Change complete';
    setModalErrorStyle(!!isError);                  // red message + red remaining amount on error

    const delay = closeMs || (isError ? CHANGER_ERROR_CLOSE_MS : 1500);
    changerCloseTimer = setTimeout(() => {
        changerCloseTimer = null;
        changerDispensing = false;
        modalNumberDisplay.innerText = '0';         // 0 -> hideNumberModal will not send another D
        setModalErrorStyle(false);
        hideNumberModal();                          // (wrapper below re-syncs lock/unlock)
    }, delay);
}

// Every line the board prints arrives here (see readSerialLoop)
function handleArduinoLine(line) {
    console.log('[Arduino]', line);
    if (!changerDispensing) return;
    armChangerAckTimer();                           // board is alive -> keep waiting

    let m;
    if ((m = line.match(/^Hopper Coin (\d+)/))) {
        setChangerRemaining(changerTotal - parseInt(m[1], 10) * CHANGER_COIN_VALUE);   // 100 -> 95 -> 90 ...
    } else if (/dispense rejected: LOCKED/i.test(line)) {
        logKioskEvent("Bill Changer Error: Dispenser is locked", changerTotal.toString(), false, "CHANGER");
        finishChangerDispense('Dispenser is locked', true);
    } else if (/^Invalid amount/i.test(line)) {
        logKioskEvent("Bill Changer Error: Invalid amount sent to board", changerTotal.toString(), false, "CHANGER");
        finishChangerDispense('Invalid amount', true);
    } else if (/^STOP: DONE/i.test(line)) {
        if (changerKept > 0) {
            setChangerRemaining(0);
            logKioskEvent(`Bill Changer Partial Dispense: Inserted amount had ₱${changerKept} kept/short due to whole-coin rules.`, (changerTotal + changerKept).toString(), false, "CHANGER");
            finishChangerDispense(`Insufficient amount. ${PESO}${changerKept} kept by the machine`, true, CHANGER_ERROR_CLOSE_MS);
        } else {
            logKioskEvent("Bill Changer Success: Change complete successfully.", changerTotal.toString(), true, "CHANGER");
            finishChangerDispense('Change complete', false);
        }
    } else if (/^STOP: /i.test(line)) {
        changerHadError = true;                     // jam / empty hopper: wait for the "Coins out" line
        logKioskEvent(`Bill Changer Hardware Warning: ${line}`, changerTotal.toString(), false, "CHANGER");
    } else if (changerHadError && (m = line.match(/Coins out\s*:\s*(\d+)/))) {
        const remaining = Math.max(0, changerTotal - parseInt(m[1], 10) * CHANGER_COIN_VALUE);
        setChangerRemaining(remaining);
        const msg = remaining > 0
            ? `Not enough coins. ${PESO}${remaining} not dispensed. Hopper empty or jammed - see attendant`
            : 'Hopper empty or jammed - see attendant';

        logKioskEvent(`Bill Changer Jam/Empty Error: ${msg}. Remaining due back: ₱${remaining}`, changerTotal.toString(), false, "CHANGER");
        finishChangerDispense(msg, true, CHANGER_HOPPER_ERROR_CLOSE_MS);
    }
}

// --- 2. DYNAMIC WALLPAPER DISCOVERY & SLIDER ---
const folderPath = 'Uploads/Wallpapers/';
const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
const sliderContainer = document.getElementById('slider');
const loadingText = document.getElementById('loadingText');

let validImages = [];
let slideIndex = 0;

function checkImageExists(url) {
    return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => resolve(true);
        img.onerror = () => resolve(false);
        img.src = url;
    });
}

async function discoverImages() {
    let index = 1;
    while (true) {
        let found = false;
        for (const ext of imageExtensions) {
            const testPath = `${folderPath}${index}${ext}`;
            if (await checkImageExists(testPath)) {
                validImages.push(testPath);
                found = true;
                break;
            }
        }
        if (!found) break;
        index++;
    }

    if (validImages.length > 0) {
        if (loadingText) loadingText.remove();
        initSlider();
    } else {
        if (loadingText) loadingText.innerText = 'No wallpapers found in Uploads/Wallpapers/';
    }
}

function initSlider() {
    validImages.forEach((src, idx) => {
        const slide = document.createElement('div');
        slide.classList.add('slide');
        if (idx === 0) slide.classList.add('active');
        slide.style.backgroundImage = `url('${src}')`;
        sliderContainer.appendChild(slide);
    });

    if (validImages.length > 1) {
        setInterval(nextSlide, 10000);
    }
}

function nextSlide() {
    const slides = document.querySelectorAll('.slide');
    slides[slideIndex].classList.remove('active');
    slideIndex = (slideIndex + 1) % slides.length;
    slides[slideIndex].classList.add('active');
}

// --- 3. STATUS CALCULATION ---
function getClientStatus(client) {
    if (!client) return "Offline";

    const status = client.status || client.Status;
    if (status) {
        return status;
    }

    return "Available";
}

function getUserType(client) {
    const raw = client.userType || client.UserType || client.memberType || client.accountType || '';
    const t = String(raw).trim();
    if (/vip/i.test(t)) return { text: 'VIP', cls: 'vip', colorClass: 'vip-gold', userClass: 'user-vip' };
    if (t && !/guest/i.test(t)) {
        const isMem = /member/i.test(t);
        return { text: isMem ? 'MEMBER' : t.toUpperCase(), cls: 'member', colorClass: 'member-sky', userClass: 'user-member' };
    }
    return { text: 'GUEST', cls: 'guest', colorClass: 'member-sky', userClass: 'user-member' };
}

// --- 4. FETCH CLIENT DATA & CAROUSEL RENDERING ---
const pspContainer = document.getElementById('pspContainer');
const pspCarousel = document.getElementById('pspCarousel');
let selectedIndex = 0;
let clientData = [];
let filteredClientData = [];

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
                renderPSPMenu();
                renderAttractGrid();
                syncArduinoState();
            }
        }
    } catch (err) {
        console.error('Failed to fetch computer data from handler:', err);
    }
}

function renderPSPMenu() {
    pspCarousel.innerHTML = '';

    let filteredData = clientData.filter(client => {
        const status = getClientStatus(client);
        return status === "Available" || status === "Occupied" || status === "Offline" || status === "Paused" || status === "Administrator";
    });

    if (document.getElementById('Label_Layers').innerHTML === '3') {
        filteredData.push({
            clientName: "Bill Changer",
            status: "Available",
            isCoinChanger: true,
            ipAddress: "-",
            timeStart: null,
            timeEnd: null
        });
    }

    filteredClientData = filteredData.sort((a, b) => {
        const nameA = a.clientName || a.ClientName || '';
        const nameB = b.clientName || b.ClientName || '';
        return nameA.localeCompare(nameB, undefined, { numeric: true, sensitivity: 'base' });
    });

    const totalItems = filteredClientData.length;
    if (selectedIndex >= totalItems) {
        selectedIndex = Math.max(0, totalItems - 1);
    }

    filteredClientData.forEach((client, index) => {
        const isBillChanger = client.isCoinChanger;
        const status = getClientStatus(client);

        let statusClass = isBillChanger ? `status-coin-changer` : `status-${status.toLowerCase()}`;
        let badgeText = status;
        let extraCardClasses = '';

        if (status === "Occupied") {
            const user = getUserType(client);
            badgeText = user.text;
            statusClass = `status-occupied ${user.userClass}`;
            extraCardClasses = user.colorClass;
        }

        const timeStart = client.timeStart || client.TimeStart;
        const timeEnd = client.timeEnd || client.TimeEnd;
        const ipAddress = client.ipAddress || client.IPAddress;
        const clientName = client.clientName || client.ClientName;

        const formattedStart = formatDateTimeString(timeStart);
        const formattedEnd = formatDateTimeString(timeEnd);

        const card = document.createElement('div');
        card.className = `psp-card ${index === selectedIndex ? 'active' : ''} ${statusClass} ${extraCardClasses}`;

        if (isBillChanger) {
            card.innerHTML = `
                <div class="pc-icon-wrapper">💵</div>
                <div class="pc-title">Bill Changer</div>
                <div class="pc-details">
                    Utility / Bills<br>
                    Insert & Exchange
                </div>
                <div class="psp-badge status-coin-changer">
                    Active
                </div>
            `;
        } else {

            //${ipAddress && ipAddress !== '-' ? `${ipAddress}<br>` : ''} Backup pag gusto pa mag lagay ng IP Address
            card.innerHTML = `
                <div class="pc-icon-wrapper">💻</div>
                <div class="pc-title">${clientName || `PC-${String(index + 1).padStart(2, '0')}`}</div>
                <div class="pc-details">
                    ${ipAddress && ipAddress !== '-' || formattedStart || formattedEnd
                    ? `
                        ${formattedStart ? `${formattedStart}<br>` : ''}
                        ${formattedEnd ? `${formattedEnd}` : ''}
                      `
                    : 'Not Available'
                }
                </div>
                <div class="psp-badge ${statusClass}">
                    ${badgeText}
                </div>
            `;
        }

        card.addEventListener('click', () => {
            if (isModalOpen()) return;
            if (Math.abs(currentDeltaX) < 10) {
                selectedIndex = index;
                updateCarouselPosition(0);
            }
        });

        pspCarousel.appendChild(card);
    });

    requestAnimationFrame(() => updateCarouselPosition(0));
}

let lastSpokenPC = "";
function updateCarouselPosition(extraOffset = 0) {
    const cards = document.querySelectorAll('.psp-card');
    if (cards.length === 0) return;

    cards.forEach((card, idx) => {
        card.classList.toggle('active', idx === selectedIndex);
    });

    if (pspContainer.style.display === 'none') return;

    const target = cards[selectedIndex];

    if (target) {
        const titleEl = target.querySelector('.pc-title');
        const pcName = titleEl ? titleEl.innerText : `PC-${String(selectedIndex + 1).padStart(2, '0')}`;

        if (pcName !== lastSpokenPC) {
            lastSpokenPC = pcName;
            speakText(pcName);
        }
    }

    const cardCenter = (target.offsetLeft - pspCarousel.offsetLeft) + (target.offsetWidth / 2);
    const totalTranslate = (window.innerWidth / 2) - cardCenter + extraOffset;

    pspCarousel.style.transform = `translate3d(${totalTranslate}px, 0px, 0px)`;
    pspCarousel.style.webkitTransform = `translate3d(${totalTranslate}px, 0px, 0px)`;

    syncArduinoState();
}

// --- 5. TOUCH / SWIPE DRAG ENGINE ---
let startX = 0;
let currentDeltaX = 0;
let isDragging = false;

function onPointerDown(e) {
    if (isModalOpen() || filteredClientData.length === 0) return;
    isDragging = true;
    startX = e.clientX || (e.touches && e.touches[0].clientX);
    currentDeltaX = 0;
    pspCarousel.style.transition = 'none';
}

function onPointerMove(e) {
    if (!isDragging || isModalOpen()) return;
    const currentX = e.clientX || (e.touches && e.touches[0].clientX);
    currentDeltaX = currentX - startX;
    updateCarouselPosition(currentDeltaX);
}

function onPointerUp() {
    if (!isDragging) return;
    isDragging = false;

    pspCarousel.style.transition = 'transform 0.4s cubic-bezier(0.25, 1, 0.5, 1)';
    const swipeThreshold = window.innerWidth * 0.12;

    if (currentDeltaX < -swipeThreshold && selectedIndex < filteredClientData.length - 1) {
        selectedIndex++;
    } else if (currentDeltaX > swipeThreshold && selectedIndex > 0) {
        selectedIndex--;
    }

    updateCarouselPosition(0);
}

pspContainer.addEventListener('mousedown', onPointerDown);
window.addEventListener('mousemove', onPointerMove);
window.addEventListener('mouseup', onPointerUp);

pspContainer.addEventListener('touchstart', onPointerDown, { passive: true });
window.addEventListener('touchmove', onPointerMove, { passive: true });
window.addEventListener('touchend', onPointerUp);

window.addEventListener('resize', () => updateCarouselPosition(0));
window.addEventListener('orientationchange', () => setTimeout(() => updateCarouselPosition(0), 150));

let isWheelCoolingDown = false;
pspContainer.addEventListener('wheel', (e) => {
    if (isModalOpen() || filteredClientData.length === 0 || isWheelCoolingDown) return;

    if (e.deltaY > 0 || e.deltaX > 0) {
        if (selectedIndex < filteredClientData.length - 1) {
            selectedIndex++;
            updateCarouselPosition();
        }
    } else {
        if (selectedIndex > 0) {
            selectedIndex--;
            updateCarouselPosition();
        }
    }

    isWheelCoolingDown = true;
    setTimeout(() => { isWheelCoolingDown = false; }, 200);
});

document.addEventListener('keydown', (e) => {
    if (isPressAnyKeyVisible()) {
        if (e.key === 'ArrowLeft' || e.key === 'ArrowRight' || (e.ctrlKey && (e.key.toLowerCase() === 'a' || e.key.toLowerCase() === 'c'))) {
            e.preventDefault();

            serialTask(async () => {
                if (await openSerial(true)) {
                    hidePressAnyKey();
                    await serialWriter.write(new TextEncoder().encode(shouldLock() ? 'L' : 'U'));
                }
            });
            return;
        }
        e.preventDefault();
        return;
    }

    if (e.key >= '0' && e.key <= '9') {
        if (filteredClientData && filteredClientData.length > 0 && selectedIndex >= 0 && selectedIndex < filteredClientData.length) {
            const currentClient = filteredClientData[selectedIndex];
            const currentStatus = getClientStatus(currentClient);
            if (currentStatus === "Offline" || currentStatus === "Administrator" || currentStatus === "Paused") {
                e.preventDefault();
                e.stopPropagation();
                return;
            }
        }

        e.preventDefault();
        e.stopPropagation();
        handleNumberInput(e.key);
        return;
    }

    if (e.key === 'Enter' && (pendingDigits || isModalOpen())) {
        if (filteredClientData && filteredClientData.length > 0 && selectedIndex >= 0 && selectedIndex < filteredClientData.length) {
            const currentClient = filteredClientData[selectedIndex];
            const currentStatus = getClientStatus(currentClient);
            if (currentStatus === "Offline" || currentStatus === "Administrator" || currentStatus === "Paused") {
                e.preventDefault();
                e.stopPropagation();
                return;
            }
        }

        e.preventDefault();
        e.stopPropagation();
        handleEnterInput();
        return;
    }

    if (isModalOpen() || filteredClientData.length === 0) return;

    if (e.key === 'ArrowRight' || (e.ctrlKey && e.key.toLowerCase() === 'c')) {
        e.preventDefault();
        if (selectedIndex < filteredClientData.length - 1) {
            selectedIndex++;
            updateCarouselPosition();
        }
    } else if (e.key === 'ArrowLeft' || (e.ctrlKey && e.key.toLowerCase() === 'a')) {
        e.preventDefault();
        if (selectedIndex > 0) {
            selectedIndex--;
            updateCarouselPosition();
        }
    } else {
        e.preventDefault();
        e.stopPropagation();
    }
});

// --- 6. INITIALIZATION & SSE ---
window.addEventListener('load', function () {
    const endpoint = window.location.protocol + '//' + window.location.hostname + ':2050/sse';
    let evtSource = null;

    try {
        evtSource = new EventSource(endpoint);

        evtSource.onmessage = function (event) {
            fetchClientData();

            const LinkButton_Refresh = document.querySelector('[id$="LinkButton_Refresh"]');
            if (LinkButton_Refresh) {
                LinkButton_Refresh.click();
            }
        };

        evtSource.onerror = function (err) {
            console.error('SSE Error/Disconnected:', err);
        };
    } catch (e) {
        console.error('Failed to initialize SSE:', e);
    }
    resetIdleTimer();
});

function formatDateTimeString(dateStr) {
    if (!dateStr || dateStr.trim() === "") return "";

    if (dateStr.includes("9999-12-31")) {
        return "∞";
    }

    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;

    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    const month = months[d.getMonth()];
    const day = String(d.getDate()).padStart(2, '0');

    let hours = d.getHours();
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';

    hours = hours % 12;
    hours = hours ? hours : 12;
    const formattedHours = String(hours).padStart(2, '0');

    return `${month} ${day} – ${formattedHours}:${minutes} ${ampm}`;
}

discoverImages();
fetchClientData();

function toggleFullScreen() {
    const icon = document.getElementById('fullscreenIcon');

    if (!document.fullscreenElement && !document.webkitFullscreenElement && !document.msFullscreenElement) {
        const docEl = document.documentElement;
        if (docEl.requestFullscreen) {
            docEl.requestFullscreen();
        } else if (docEl.webkitRequestFullscreen) {
            docEl.webkitRequestFullscreen();
        } else if (docEl.msRequestFullscreen) {
            docEl.msRequestFullscreen();
        }
        if (icon) {
            icon.classList.remove('fa-expand');
            icon.classList.add('fa-compress');
        }
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
        }
        if (icon) {
            icon.classList.remove('fa-compress');
            icon.classList.add('fa-expand');
        }
    }
}

document.addEventListener('fullscreenchange', () => {
    const icon = document.getElementById('fullscreenIcon');
    if (!icon) return;

    if (document.fullscreenElement) {
        icon.classList.remove('fa-expand');
        icon.classList.add('fa-compress');
    } else {
        icon.classList.remove('fa-compress');
        icon.classList.add('fa-expand');
    }
});

// ---------------- Web Serial ----------------
let serialPort = null;
let serialWriter = null;
let serialQueue = Promise.resolve();
let serialReader = null;

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
        return false;
    }
    if (serialWriter) return true;

    if (!serialPort) {
        const ports = await navigator.serial.getPorts();
        serialPort = ports[0] || null;
        if (!serialPort && allowPrompt) serialPort = await navigator.serial.requestPort();
        if (!serialPort) return false;
    }
    if (!serialPort.writable) await serialPort.open({ baudRate: 9600 });
    serialWriter = serialPort.writable.getWriter();
    readSerialLoop(serialPort);
    return true;
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

function shouldLock() {
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

function syncArduinoState() {
    sendSerialCommand(shouldLock() ? 'L' : 'U');
}

document.addEventListener('click', function (e) {
    if (!e.target.closest || !e.target.closest('#pressAnyKeyScreen')) return;

    serialTask(async () => {
        if (await openSerial(true)) {
            hidePressAnyKey();
            await serialWriter.write(new TextEncoder().encode(shouldLock() ? 'L' : 'U'));
        }
    });
});

if ('serial' in navigator) {
    navigator.serial.addEventListener('disconnect', () => { serialWriter = null; serialPort = null; });
    navigator.serial.addEventListener('connect', () => syncArduinoState());
}

const originalShowNumberModal = showNumberModal;
showNumberModal = function (pcName) {
    originalShowNumberModal(pcName);
    if (LOCK_WHILE_MODAL_OPEN) sendSerialCommand('L');
};

const originalHideNumberModal = hideNumberModal;
hideNumberModal = function () {
    originalHideNumberModal();
    syncArduinoState();
};

if (document.readyState === 'complete') showPressAnyKey();
else window.addEventListener('load', showPressAnyKey);

function getPressAnyKeyScreen() {
    return document.getElementById('pressAnyKeyScreen');
}

function isPressAnyKeyVisible() {
    const screen = getPressAnyKeyScreen();
    return !!screen && screen.style.display !== 'none';
}

function escapeHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

let serverTimeOffset = null;

async function fetchServerTime() {
    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/GetTimeServiceHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/GetTimeServiceHandler.ashx');

    const response = await fetch(endpoint, { cache: 'no-store' });
    if (!response.ok) throw new Error('Network response was not ok');
    const data = await response.json();
    return new Date(data.serverTime).getTime();
}

async function syncServerTime() {
    try {
        const serverNow = await fetchServerTime();
        serverTimeOffset = serverNow - (performance.timeOrigin + performance.now());
    } catch (err) {
        console.warn('Failed to sync server time:', err);
    }
}

function getServerNow() {
    return performance.timeOrigin + performance.now() + (serverTimeOffset || 0);
}

function getRemainingSeconds(client) {
    const endStr = client.timeEnd || client.TimeEnd;
    if (!endStr || String(endStr).includes('9999-12-31') || String(endStr).trim() === "") return null;

    const end = Date.parse(String(endStr).replace(" ", "T"));
    if (isNaN(end)) return 0;

    return Math.max(0, Math.floor((end - getServerNow()) / 1000));
}
function buildAttractCard(client, index) {
    const status = getClientStatus(client);
    const running = (status === 'Occupied');

    let theme = status === 'Paused' ? 'theme-orange'
        : status === 'Administrator' ? 'theme-purple'
            : status === 'Available' ? 'theme-green' : 'theme-gray';

    let pillText = status === 'Paused' ? 'PAUSED'
        : status === 'Administrator' ? 'ADMINISTRATOR'
            : status === 'Available' ? 'AVAILABLE' : 'OFFLINE';

    let pillCls = status === 'Paused' ? 'pill-paused'
        : status === 'Administrator' ? 'pill-admin'
            : status === 'Available' ? 'pill-available' : 'pill-offline';

    let colorThemeClass = '';

    if (status === 'Occupied' || status === 'Paused') {
        const user = getUserType(client);
        const statusLabel = status === 'Paused' ? ' · PAUSED' : '';
        pillText = `${user.text}${statusLabel}`;
        pillCls = status === 'Paused' ? 'pill-paused' : user.userClass;

        if (user.cls === 'vip') {
            theme = status === 'Paused' ? 'theme-orange vip-gold' : 'theme-red vip-gold';
            colorThemeClass = 'vip-gold';
        } else {
            theme = status === 'Paused' ? 'theme-orange member-sky' : 'theme-red member-sky';
            colorThemeClass = 'member-sky';
        }
    }

    const name = client.ClientName || `PC-${String(index + 1).padStart(2, '0')}`;
    const endAttr = (running && client.TimeEnd) ? escapeHtml(client.TimeEnd) : '';

    // Determine the label text for the time box depending on the status
    let timeLabelText = '<i class="far fa-clock"></i> TIME';
    if (status === 'Paused') {
        timeLabelText = '<i class="fas fa-pause-circle"></i> SESSION PAUSED';
    } else if (status === 'Administrator') {
        timeLabelText = '<i class="fas fa-user-shield"></i> IN USE BY ADMIN';
    }

    return `
        <div class="atc-wrap ${theme} ${colorThemeClass}">
          <div class="atc"><div class="atc-in">
            <div class="atc-top">
              <div class="atc-pill ${pillCls}">${pillText}</div>
              <div class="atc-identity">
                <i class="fas fa-desktop"></i>
                <div class="atc-name">${escapeHtml(name)}</div>
              </div>
            </div>
            <div class="atc-time">
              <div class="atc-label">${timeLabelText}</div>
              <div class="atc-digits" data-end="${endAttr}" data-running="${running ? 1 : 0}"></div>
              <div class="atc-units"><span>Hour</span><span>|</span><span>Minutes</span><span>|</span><span>Seconds</span></div>
            </div>
          </div></div>
        </div>`;
}
function renderAttractGrid() {
    const grid = document.getElementById('attractGrid');
    if (!grid) return;

    const list = clientData.slice().sort((a, b) =>
        (a.ClientName || '').localeCompare(b.ClientName || '', undefined, { numeric: true, sensitivity: 'base' }));

    const count = list.length;
    if (count === 0) {
        grid.innerHTML = '';
        return;
    }

    let cols = 4;

    if (count <= 4) {
        cols = count;
    } else {
        const screenAspect = window.innerWidth / Math.max(1, window.innerHeight);
        cols = Math.ceil(Math.sqrt(count * screenAspect * 0.7));
        cols = Math.max(2, Math.min(cols, count));
    }

    grid.style.setProperty('--cols', cols);

    grid.innerHTML = list.map(buildAttractCard).join('');
    tickAttractTimes();
}

window.addEventListener('resize', () => {
    if (isPressAnyKeyVisible()) {
        renderAttractGrid();
    }
});

function tickAttractTimes() {
    document.querySelectorAll('#attractGrid .atc-digits').forEach(el => {
        let html;
        if (el.dataset.running !== '1') {
            html = '<span>00</span><span class="sep">:</span><span>00</span><span class="sep">:</span><span>00</span>';
        } else {
            const secs = getRemainingSeconds({ TimeEnd: el.dataset.end });
            if (secs === null) {
                html = '<span class="inf">&infin;</span>';
            } else {
                const p = n => String(n).padStart(2, '0');
                html = `<span>${p(Math.floor(secs / 3600))}</span><span class="sep">:</span>` +
                    `<span>${p(Math.floor((secs % 3600) / 60))}</span><span class="sep">:</span>` +
                    `<span>${p(secs % 60)}</span>`;
            }
        }
        if (el.innerHTML !== html) el.innerHTML = html;
    });
}

syncServerTime().then(() => {
    if (typeof tickAttractTimes === 'function') tickAttractTimes();
});
setInterval(syncServerTime, 5 * 60 * 1000);

setInterval(() => { if (isPressAnyKeyVisible()) tickAttractTimes(); }, 1000);

function speakText(text) {
    if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();

        const utterance = new SpeechSynthesisUtterance(text);
        utterance.rate = 1.5;
        utterance.pitch = 2.0;
        window.speechSynthesis.speak(utterance);
    }
}

let sharedAudioCtx = null;

function getAudioContext() {
    if (!sharedAudioCtx) {
        const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
        if (AudioCtxClass) {
            sharedAudioCtx = new AudioCtxClass();
        }
    }
    if (sharedAudioCtx && sharedAudioCtx.state === 'suspended') {
        sharedAudioCtx.resume();
    }
    return sharedAudioCtx;
}

function playCoinSound() {
    try {
        const ctx = getAudioContext();
        if (!ctx) return;

        const now = ctx.currentTime;

        const masterGain = ctx.createGain();
        masterGain.gain.setValueAtTime(0.35, now);
        masterGain.connect(ctx.destination);

        const metallicFrequencies = [2400, 3100];

        metallicFrequencies.forEach((freq, i) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, now);
            osc.frequency.exponentialRampToValueAtTime(freq * 0.9, now + 0.12);

            gain.gain.setValueAtTime(0.12, now);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + (i === 0 ? 0.1 : 0.15));

            osc.connect(gain);
            gain.connect(masterGain);

            osc.start(now);
            osc.stop(now + 0.16);
        });

        const thudOsc = ctx.createOscillator();
        const thudGain = ctx.createGain();

        thudOsc.type = 'triangle';
        thudOsc.frequency.setValueAtTime(600, now);
        thudOsc.frequency.exponentialRampToValueAtTime(200, now + 0.04);

        thudGain.gain.setValueAtTime(0.15, now);
        thudGain.gain.exponentialRampToValueAtTime(0.0001, now + 0.04);

        thudOsc.connect(thudGain);
        thudGain.connect(masterGain);

        thudOsc.start(now);
        thudOsc.stop(now + 0.05);

    } catch (e) {
        console.warn("Web Audio API not supported or blocked:", e);
    }
}