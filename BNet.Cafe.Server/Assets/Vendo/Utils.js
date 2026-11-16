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

// ---------------------------------------------------------------------------
// Speech
// ---------------------------------------------------------------------------
const SPEECH_DEFAULT_RATE = 1.3;   // safe default for every PC
const SPEECH_MAX_RATE = 1.6;       // hard cap so it never gets unreadable (raise to 1.7 only after testing)
const SPEECH_PITCH = 1.3;

// Male voice preference, first match wins. Different browsers/OSes name voices differently.
const MALE_VOICE_PATTERNS = [
    /david/i,                                   // Microsoft David (Windows)
    /\bmark\b/i,                                // Microsoft Mark (Windows)
    /\b(guy|ryan|christopher|eric|george|james|daniel|alex|fred|aaron|arthur)\b/i,
    /male/i                                     // e.g. "Google UK English Male"
];

function isFemaleName(name) {
    return /female|zira|hazel|susan|aria|jenny|samantha|karen|victoria|sonia|libby/i.test(name);
}

function getSpeechRate() {
    // Per-PC override: run localStorage.setItem('speechRate', '1.5') in the browser console
    let saved = NaN;
    try {
        saved = parseFloat(localStorage.getItem('speechRate'));
    } catch (e) { /* localStorage blocked */ }

    const rate = isNaN(saved) ? SPEECH_DEFAULT_RATE : saved;
    return Math.min(SPEECH_MAX_RATE, Math.max(0.5, rate));
}

// Pick the voice once a male voice is found and reuse it, so every call starts instantly
let cachedVoice = null;

function pickVoice() {
    if (cachedVoice) return cachedVoice;

    const voices = window.speechSynthesis.getVoices()
        .filter(v => v.lang && v.lang.toLowerCase().replace('_', '-').startsWith('en'));
    if (!voices.length) return null;

    // Voice pinned for this browser, if any
    let savedName = null;
    try {
        savedName = localStorage.getItem('speechVoice');
    } catch (e) { /* localStorage blocked */ }

    const saved = savedName && voices.find(v => v.name === savedName);
    if (saved) return (cachedVoice = saved);

    // Male voices in order of preference (local first, to avoid network delay)
    for (const pattern of MALE_VOICE_PATTERNS) {
        const matches = voices.filter(v => pattern.test(v.name) && !isFemaleName(v.name));
        const match = matches.find(v => v.localService) || matches[0];
        if (match) return (cachedVoice = match);
    }

    // No male voice in this browser: fall back to any local English voice (not cached,
    // so a male voice is picked up automatically if the list finishes loading later)
    return voices.find(v => v.localService) || voices[0];
}

function doSpeak(text) {
    // cancel() right before speak() causes a delay on some browsers, so only cancel if busy
    if (window.speechSynthesis.speaking || window.speechSynthesis.pending) {
        window.speechSynthesis.cancel();
    }

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    utterance.rate = getSpeechRate();
    utterance.pitch = SPEECH_PITCH;

    const voice = pickVoice();
    if (voice) {
        utterance.voice = voice;
        utterance.lang = voice.lang;
    }

    window.speechSynthesis.speak(utterance);
}

function speakText(text) {
    if (!('speechSynthesis' in window)) return;

    // Chrome/Edge load voices asynchronously. If the list is still empty, speaking now
    // would use the browser's default (often female) voice, so wait for it first.
    if (!window.speechSynthesis.getVoices().length) {
        let done = false;
        const go = () => {
            if (done) return;
            done = true;
            window.speechSynthesis.removeEventListener('voiceschanged', go);
            doSpeak(text);
        };
        window.speechSynthesis.addEventListener('voiceschanged', go);
        setTimeout(go, 1000); // don't wait forever
        return;
    }

    doSpeak(text);
}

if ('speechSynthesis' in window) {
    window.speechSynthesis.onvoiceschanged = () => {
        cachedVoice = null;
        pickVoice();
    };
    window.speechSynthesis.getVoices(); // warm up so the first speak() isn't slow
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Date / text helpers
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Server time
// ---------------------------------------------------------------------------
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