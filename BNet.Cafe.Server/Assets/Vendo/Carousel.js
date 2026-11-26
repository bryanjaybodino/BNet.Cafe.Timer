const pspContainer = document.getElementById('pspContainer');
const pspCarousel = document.getElementById('pspCarousel');
let selectedIndex = 0;
let filteredClientData = [];
let lastSpokenPC = "";

// ---- Drag / glide state ----
let startX = 0;
let currentDeltaX = 0;
let isDragging = false;
let samples = [];        // recent {x, t} points used to measure swipe speed
let glideTimer = null;
let rafId = null;
let isGliding = false;
let downCard = null;     // card under the finger when the touch started
let moved = false;       // true if the finger moved enough to count as a swipe
let lastTouchTime = 0;   // used to ignore the fake mouse events that follow a touch
let lastTapTime = 0;     // used so the click handler doesn't select twice

// ---- Tuning ----
const TAP_MOVE_LIMIT = 10; // px. Moving less than this = a tap, not a swipe
const VELOCITY_WINDOW_MS = 100;  // measure speed over the last 100ms
const MIN_FLICK_SPEED = 0.5;  // px/ms. Below this = normal drag (1 card)
const MAX_SPEED = 3;    // px/ms cap
const STEPS_PER_SPEED = 2;    // higher = more cards per unit of force
const MAX_STEPS = 5;    // most cards one flick can pass
const GLIDE_BASE_MS = 350;  // glide time for 1 card
const GLIDE_PER_CARD_MS = 120;  // extra time per additional card

function renderPSPMenu(clientData, onSelectCallback) {
    if (!pspCarousel) return;
    pspCarousel.innerHTML = '';

    let filteredData = clientData.filter(client => {
        const status = getClientStatus(client);
        return status === "Available" || status === "Occupied" || status === "Offline" || status === "Paused" || status === "Administrator";
    });

    if (document.getElementById('Label_CoinChanger')?.innerHTML === 'TRUE') {
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

    if (selectedIndex >= filteredClientData.length) {
        selectedIndex = Math.max(0, filteredClientData.length - 1);
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

        const formattedStart = formatDateTimeString(client.timeStart || client.TimeStart);
        const formattedEnd = formatDateTimeString(client.timeEnd || client.TimeEnd);
        const clientName = client.clientName || client.ClientName;

        const card = document.createElement('div');
        card.className = `psp-card ${index === selectedIndex ? 'active' : ''} ${statusClass} ${extraCardClasses}`;

        if (isBillChanger) {
            card.innerHTML = `
                <div class="pc-icon-wrapper">💵</div>
                <div class="pc-title bill-changer-title"><span>BILL</span><span>CHANGER</span></div>
                <div class="pc-details">Utility / Bills<br>Insert & Exchange</div>
                <div class="psp-badge status-coin-changer">Active</div>
            `;
        } else {
            const isAvailable = badgeText === "Available";
            const isOffline = badgeText === "Offline" || status === "Offline";
            card.innerHTML = `
                <div class="pc-icon-wrapper">💻</div>
                <div class="pc-title">${clientName || `PC-${String(index + 1).padStart(2, '0')}`}</div>
                <div class="pc-details">
                    ${isAvailable ? 'Insert your Coin or Bill' : isOffline ? 'Not Available' : `${formattedStart ? `${formattedStart}<br>` : ''}${formattedEnd ? `${formattedEnd}` : ''}`}
                </div>
                <div class="psp-badge ${statusClass}">${badgeText}</div>
            `;
        }

        card.addEventListener('click', () => {
            if (isModalOpen() || isClientInsertingCoin()) return; // Block clicks during modal/insert
            if (performance.now() - lastTapTime < 500) return;    // tap already handled on touch release
            if (Math.abs(currentDeltaX) < TAP_MOVE_LIMIT) {
                selectedIndex = index;
                updateCarouselPosition(0);
            }
        });

        pspCarousel.appendChild(card);
    });

    requestAnimationFrame(() => updateCarouselPosition(0));
    if (onSelectCallback) onSelectCallback(filteredClientData, selectedIndex);
}

function updateCarouselPosition(extraOffset = 0, checkSyncStateCb) {
    const cards = document.querySelectorAll('.psp-card');
    if (cards.length === 0) return;

    cards.forEach((card, idx) => {
        card.classList.toggle('active', idx === selectedIndex);
    });

    if (pspContainer.style.display === 'none') return;

    const target = cards[selectedIndex];
    if (!target) return;

    const titleEl = target.querySelector('.pc-title');
    const pcName = titleEl ? titleEl.innerText : `PC-${String(selectedIndex + 1).padStart(2, '0')}`;
    // Don't speak every card while the carousel is gliding past them
    if (pcName !== lastSpokenPC && !isGliding) {
        lastSpokenPC = pcName;
        speakText(pcName);
    }

    const cardCenter = (target.offsetLeft - pspCarousel.offsetLeft) + (target.offsetWidth / 2);
    const totalTranslate = (window.innerWidth / 2) - cardCenter + extraOffset;

    pspCarousel.style.transform = `translate3d(${totalTranslate}px, 0px, 0px)`;
    if (checkSyncStateCb) checkSyncStateCb();
}

function initCarouselEvents(updateCallback) {
    function getX(e) {
        return e.touches && e.touches.length ? e.touches[0].clientX : e.clientX;
    }

    function recordSample(x) {
        const now = performance.now();
        samples.push({ x, t: now });
        while (samples.length > 1 && now - samples[0].t > VELOCITY_WINDOW_MS) {
            samples.shift();
        }
    }

    function getVelocity() {
        if (samples.length < 2) return 0;
        const first = samples[0];
        const last = samples[samples.length - 1];
        if (performance.now() - last.t > 60) return 0; // finger stopped before release
        const dt = last.t - first.t;
        if (dt < 16) return 0; // too little data to trust
        const v = (last.x - first.x) / dt;
        return Math.max(-MAX_SPEED, Math.min(MAX_SPEED, v));
    }

    // Which card is currently closest to the screen center (even mid-animation)
    function centerIndex() {
        const cards = document.querySelectorAll('.psp-card');
        const mid = window.innerWidth / 2;
        let best = selectedIndex, bestDist = Infinity;
        cards.forEach((c, i) => {
            const r = c.getBoundingClientRect();
            const d = Math.abs(r.left + r.width / 2 - mid);
            if (d < bestDist) { bestDist = d; best = i; }
        });
        return best;
    }

    // Keeps the highlight on whichever card is passing through the center
    function trackActiveCard() {
        if (!isGliding) return;
        const best = centerIndex();
        document.querySelectorAll('.psp-card').forEach((c, i) => {
            c.classList.toggle('active', i === best);
        });
        rafId = requestAnimationFrame(trackActiveCard);
    }

    function cancelGlide() {
        clearTimeout(glideTimer);
        cancelAnimationFrame(rafId);
        glideTimer = null;
        rafId = null;
        isGliding = false;
    }

    // One continuous ease-out animation across the whole distance
    function glide(direction, count) {
        cancelGlide();

        const newIndex = Math.max(0, Math.min(filteredClientData.length - 1, selectedIndex + direction * count));
        const travelled = Math.abs(newIndex - selectedIndex);

        if (travelled === 0) {
            pspCarousel.style.transition = 'transform 0.4s cubic-bezier(0.25, 1, 0.5, 1)';
            updateCarouselPosition(0, updateCallback);
            return;
        }

        const duration = GLIDE_BASE_MS + (travelled - 1) * GLIDE_PER_CARD_MS;
        isGliding = true;

        pspCarousel.style.transition = `transform ${duration}ms cubic-bezier(0.22, 1, 0.36, 1)`;
        selectedIndex = newIndex;
        updateCarouselPosition(0, updateCallback);
        trackActiveCard();

        glideTimer = setTimeout(() => {
            isGliding = false;
            glideTimer = null;
            cancelAnimationFrame(rafId);
            updateCarouselPosition(0, updateCallback); // highlights and speaks the final card
        }, duration + 30);
    }

    function onPointerDown(e) {
        if (isModalOpen() || isClientInsertingCoin() || filteredClientData.length === 0) return;

        // Browsers fire fake mouse events right after a touch; ignore them
        if (e.type === 'touchstart') {
            lastTouchTime = performance.now();
        } else if (performance.now() - lastTouchTime < 800) {
            return;
        }

        // Remember which card the finger landed on (before anything moves)
        downCard = e.target && e.target.closest ? e.target.closest('.psp-card') : null;
        moved = false;

        // Grabbing the carousel mid-glide: stop and continue from the card in the center
        if (isGliding) {
            const current = centerIndex();
            cancelGlide();
            selectedIndex = current;
        }

        isDragging = true;
        startX = getX(e);
        samples = [{ x: startX, t: performance.now() }];
        currentDeltaX = 0;
        pspCarousel.style.transition = 'none';
    }

    function onPointerMove(e) {
        if (!isDragging || isModalOpen() || isClientInsertingCoin()) return;
        const currentX = getX(e);
        recordSample(currentX);
        currentDeltaX = currentX - startX;
        if (Math.abs(currentDeltaX) > TAP_MOVE_LIMIT) moved = true;
        updateCarouselPosition(currentDeltaX, updateCallback);
    }

    function onPointerUp(e) {
        if (!isDragging) return;
        isDragging = false;
        if (e && e.type === 'touchend') lastTouchTime = performance.now();

        // TAP: select the card that was touched, right away (even right after a glide)
        if (!moved && downCard) {
            const tappedIndex = Array.from(document.querySelectorAll('.psp-card')).indexOf(downCard);
            downCard = null;
            lastTapTime = performance.now();
            if (tappedIndex !== -1) {
                selectedIndex = tappedIndex;
                currentDeltaX = 0;
                pspCarousel.style.transition = 'transform 0.4s cubic-bezier(0.25, 1, 0.5, 1)';
                updateCarouselPosition(0, updateCallback);
                return;
            }
        }
        downCard = null;

        const velocity = getVelocity();
        const speed = Math.abs(velocity);
        const swipeThreshold = window.innerWidth * 0.12;

        let count = 0;
        let direction = currentDeltaX < 0 ? 1 : -1; // swipe left = next card

        if (speed >= MIN_FLICK_SPEED) {
            direction = velocity < 0 ? 1 : -1;
            count = 1 + Math.round((speed - MIN_FLICK_SPEED) * STEPS_PER_SPEED);
        } else if (Math.abs(currentDeltaX) > swipeThreshold) {
            count = 1;
        }

        count = Math.min(MAX_STEPS, count);

        if (count === 0) {
            // not enough movement: snap back
            pspCarousel.style.transition = 'transform 0.4s cubic-bezier(0.25, 1, 0.5, 1)';
            updateCarouselPosition(0, updateCallback);
            return;
        }

        glide(direction, count);
    }

    pspContainer.addEventListener('mousedown', onPointerDown);
    window.addEventListener('mousemove', onPointerMove);
    window.addEventListener('mouseup', onPointerUp);
    pspContainer.addEventListener('touchstart', onPointerDown, { passive: true });
    window.addEventListener('touchmove', onPointerMove, { passive: true });
    window.addEventListener('touchend', onPointerUp);

    window.addEventListener('resize', () => updateCarouselPosition(0, updateCallback));
    window.addEventListener('orientationchange', () => setTimeout(() => updateCarouselPosition(0, updateCallback), 150));
}

// The PC whose "Insert Coin" modal is currently open on the client side.
let insertCoinTargetClient = null;

function isClientInsertingCoin() {
    return insertCoinTargetClient !== null;
}

function setClientInsertOverlay(clientName) {
    let overlay = document.getElementById('clientInsertCoinOverlay');

    if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'clientInsertCoinOverlay';
        Object.assign(overlay.style, {
            position: 'fixed',
            top: '0',
            left: '0',
            width: '100vw',
            height: '100vh',
            backgroundColor: 'rgba(15, 23, 42, 0.85)',
            backdropFilter: 'blur(6px)',
            zIndex: '99999',
            display: 'none',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#f8fafc',
            textAlign: 'center',
            padding: '20px',
            userSelect: 'none'
        });
        document.body.appendChild(overlay);
    }

    if (clientName) {
        overlay.innerHTML = `
            <div style="font-size: 3.5rem; margin-bottom: 16px;">🪙</div>
            <h2 style="font-size: 2rem; font-weight: 700; margin: 0 0 12px 0; color: #22c55e;">
                ${escapeHtml(clientName)} IS INSERTING COINS
            </h2>
            <p style="font-size: 1.25rem; max-width: 500px; color: #cbd5e1; margin: 0;">
                Please wait until the customer finishes or closes their Insert Coin window.
            </p>
        `;
        overlay.style.display = 'flex';
    } else {
        overlay.style.display = 'none';
    }
}

function sameClientName(a, b) {
    return String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
}

// Send the amount typed in on the kiosk to the PC that is inserting (only if it owns the kiosk).
function reportInsertedAmount(pcName, amount) {
    if (!insertCoinTargetClient || !sameClientName(insertCoinTargetClient, pcName)) return;
    if (typeof sendInsertAmountToPC === 'function') {
        sendInsertAmountToPC(insertCoinTargetClient, amount);
    }
}

// Kiosk just locked -> close that PC's Insert Coin modal (once).
function closeInsertCoinModalOnClient() {
    if (!insertCoinTargetClient) return;
    const target = insertCoinTargetClient;
    insertCoinTargetClient = null;
    setClientInsertOverlay(null); // Hide warning overlay
    if (typeof sendCloseModalToPC === 'function') sendCloseModalToPC(target);
}

// Client closed its Insert Coin modal -> unlock UI and lock the kiosk.
function lockKioskForClient(clientName) {
    if (!insertCoinTargetClient || !sameClientName(insertCoinTargetClient, clientName)) return;
    insertCoinTargetClient = null;
    setClientInsertOverlay(null); // Hide warning overlay

    if (isModalOpen() || changerDispensing) return;

    if (!isPressAnyKeyVisible()) forceLockSystem(sendSerialCommand);
}

function autoSelectClientInCarousel(targetClientName) {
    if (!targetClientName) return;

    const resetIdle = () => resetIdleTimer(isModalOpen, changerDispensing, updateCarouselPosition);
    const syncBoard = () => syncArduinoState(filteredClientData, selectedIndex, clientData, changerDispensing, isModalOpen);

    if (isPressAnyKeyVisible()) {
        hidePressAnyKey(() => updateCarouselPosition(0), resetIdle);
    } else {
        resetIdle();
    }

    // Remember who is inserting and display the blocking message overlay
    insertCoinTargetClient = targetClientName;
    setClientInsertOverlay(targetClientName);

    if (!filteredClientData || filteredClientData.length === 0) {
        syncBoard();
        return;
    }

    const wanted = String(targetClientName).trim().toLowerCase();
    const targetIndex = filteredClientData.findIndex(client => {
        const name = client.clientName || client.ClientName || '';
        return String(name).trim().toLowerCase() === wanted;
    });

    if (targetIndex !== -1) {
        selectedIndex = targetIndex;
        pspCarousel.style.transition = 'transform 0.4s cubic-bezier(0.25, 1, 0.5, 1)';
        updateCarouselPosition(0);

        if (typeof speakText === 'function') {
            speakText(`Terminal ${targetClientName} selected.`);
        }
    }

    // Keeps physical bill/coin acceptor unlocked ('U') so the user can insert coins
    syncBoard();
}