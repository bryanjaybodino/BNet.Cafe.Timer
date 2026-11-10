function getClientStatus(client) {
    if (!client) return "Offline";
    const status = client.status || client.Status;
    if (status) return status;
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

    let timeLabelText = '<i class="far fa-clock"></i> TIME';
    if (status === 'Paused') timeLabelText = '<i class="fas fa-pause-circle"></i> SESSION PAUSED';
    else if (status === 'Administrator') timeLabelText = '<i class="fas fa-user-shield"></i> IN USE BY ADMIN';

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

function renderAttractGrid(clientData) {
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

setInterval(() => { if (isPressAnyKeyVisible()) tickAttractTimes(); }, 1000);