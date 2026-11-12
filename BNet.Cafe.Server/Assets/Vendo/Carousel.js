const pspContainer = document.getElementById('pspContainer');
const pspCarousel = document.getElementById('pspCarousel');
let selectedIndex = 0;
let filteredClientData = [];
let lastSpokenPC = "";

function renderPSPMenu(clientData, onSelectCallback) {
    if (!pspCarousel) return;
    pspCarousel.innerHTML = '';

    let filteredData = clientData.filter(client => {
        const status = getClientStatus(client);
        return status === "Available" || status === "Occupied" || status === "Offline" || status === "Paused" || status === "Administrator";
    });

    if (document.getElementById('Label_Layers')?.innerHTML === '3') {
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
            if (isModalOpen()) return;
            if (Math.abs(currentDeltaX) < 10) {
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
    if (checkSyncStateCb) checkSyncStateCb();
}

let startX = 0;
let currentDeltaX = 0;
let isDragging = false;

function initCarouselEvents(updateCallback) {
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
        updateCarouselPosition(currentDeltaX, updateCallback);
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
        updateCarouselPosition(0, updateCallback);
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