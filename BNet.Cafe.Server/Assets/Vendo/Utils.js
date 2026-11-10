const PESO = '\u20B1';

function logKioskEvent(details, amount, isSuccess, type = "ACCEPTOR") {
    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/LogKioskEventHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/LogKioskEventHandler.ashx');

    var url = endpoint + '?details=' + encodeURIComponent(details) +
        '&amount=' + encodeURIComponent(amount || '0') +
        '&isSuccess=' + encodeURIComponent(isSuccess ? 'TRUE' : 'FALSE') +
        '&type=' + encodeURIComponent(type);

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

function speakText(text) {
    if ('speechSynthesis' in window) {
        window.speechSynthesis.cancel();
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.rate = 1.2;
        utterance.pitch = 1.3;

        const voices = window.speechSynthesis.getVoices();
        const preferredVoice = voices.find(v => v.lang.includes('en') && (v.name.includes('Natural') || v.name.includes('Google') || v.name.includes('Microsoft')));
        if (preferredVoice) {
            utterance.voice = preferredVoice;
        }
        window.speechSynthesis.speak(utterance);
    }
}

if ('speechSynthesis' in window) {
    window.speechSynthesis.onvoiceschanged = () => {
        window.speechSynthesis.getVoices();
    };
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

        [2400, 3100].forEach((freq, i) => {
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

function formatDateTimeString(dateStr) {
    if (!dateStr || dateStr.trim() === "") return "";
    if (dateStr.includes("9999-12-31")) return "∞";

    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;

    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const month = months[d.getMonth()];
    const day = String(d.getDate()).padStart(2, '0');

    let hours = d.getHours();
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;

    return `${month} ${day} – ${String(hours).padStart(2, '0')}:${minutes} ${ampm}`;
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