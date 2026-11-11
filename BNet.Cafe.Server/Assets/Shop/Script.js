'use strict';

// URL Parameter Parsing
const urlParams = new URLSearchParams(window.location.search);
const clientName = (urlParams.get('ClientName') || urlParams.get('clientName') || '').toUpperCase();
const userId = urlParams.get('userId') || '';

// Unique identifier for the current user session (falls back to clientName or guest if no userId exists)
const userIdentifier = userId || clientName || 'guest';

// WebSocket Setup
const encoder = new TextEncoder();
let agentWs = null;

function connectAgentWS() {
    agentWs = new WebSocket(`ws://${window.location.hostname}:2050/ws/agent`);
    agentWs.binaryType = 'arraybuffer';

    agentWs.onopen = () => {
        sendPayload(0x03, {
            ClientName: clientName,
            windowTitle: "Kiosk Store Online"
        });
    };

    agentWs.onclose = () => {
        setTimeout(connectAgentWS, 3000);
    };
}

function sendPayload(frameType, obj) {
    if (!agentWs || agentWs.readyState !== WebSocket.OPEN) return;
    const jsonBytes = encoder.encode(JSON.stringify(obj));
    const payload = new Uint8Array(1 + jsonBytes.length);
    payload[0] = frameType;
    payload.set(jsonBytes, 1);
    agentWs.send(payload.buffer);
}

// LocalStorage Cart Logic (Tied to specific user ID)
const CART_STORAGE_KEY = `kiosk_cart_${userIdentifier}`;
let cart = JSON.parse(localStorage.getItem(CART_STORAGE_KEY) || '[]');

function saveCart() {
    localStorage.setItem(CART_STORAGE_KEY, JSON.stringify(cart));
    updateCartUI();
}

// LocalStorage Order History Logic (Tied to specific user ID)
const HISTORY_STORAGE_KEY = `kiosk_order_history_${userIdentifier}`;
let orderHistory = JSON.parse(localStorage.getItem(HISTORY_STORAGE_KEY) || '[]');

function saveOrderHistory() {
    localStorage.setItem(HISTORY_STORAGE_KEY, JSON.stringify(orderHistory));
    updateHistoryUI();
}

function addToCart(id, name, price, maxStock, clickedButton) {
    const existing = cart.find(item => item.id === id);
    if (existing) {
        if (existing.qty < maxStock) {
            existing.qty++;
        } else {
            alert(`Maximum stock reached (${maxStock}) for ${name}`);
            return;
        }
    } else {
        cart.push({ id, name, price: parseFloat(price), qty: 1, maxStock: parseInt(maxStock, 10) });
    }

    saveCart();

    if (clickedButton) {
        animateFlyToCart(clickedButton);
    }
}

// Flying Bubble & Cart Bounce Animation Effect
function animateFlyToCart(sourceEl) {
    const cartToggle = document.getElementById('cartToggle');
    if (!cartToggle || !sourceEl) return;

    const sourceRect = sourceEl.getBoundingClientRect();
    const cartRect = cartToggle.getBoundingClientRect();

    const bubble = document.createElement('div');
    bubble.className = 'fly-to-cart-bubble';

    const icon = document.createElement('i');
    icon.className = 'fa fa-shopping-bag';
    bubble.appendChild(icon);

    const startX = sourceRect.left + (sourceRect.width / 2) - 18;
    const startY = sourceRect.top + (sourceRect.height / 2) - 18;
    const targetX = cartRect.left + (cartRect.width / 2) - 18;
    const targetY = cartRect.top + (cartRect.height / 2) - 18;

    bubble.style.left = `${startX}px`;
    bubble.style.top = `${startY}px`;

    document.body.appendChild(bubble);

    requestAnimationFrame(() => {
        bubble.style.transform = `translate(${targetX - startX}px, ${targetY - startY}px) scale(0.4)`;
        bubble.style.opacity = '0.2';
    });

    setTimeout(() => {
        cartToggle.classList.remove('cart-bump');
        void cartToggle.offsetWidth;
        cartToggle.classList.add('cart-bump');
        bubble.remove();
    }, 600);
}

function updateQuantity(id, change) {
    const itemIndex = cart.findIndex(item => item.id === id);
    if (itemIndex > -1) {
        cart[itemIndex].qty += change;
        if (cart[itemIndex].qty <= 0) {
            cart.splice(itemIndex, 1);
        } else if (cart[itemIndex].qty > cart[itemIndex].maxStock) {
            cart[itemIndex].qty = cart[itemIndex].maxStock;
            alert(`Maximum available stock reached.`);
        }
        saveCart();
    }
}

function removeFromCart(id) {
    cart = cart.filter(item => item.id !== id);
    saveCart();
}

function clearCart() {
    cart = [];
    saveCart();
}

// Render Cart UI
function updateCartUI() {
    const badge = document.getElementById('cartBadgeCount');
    const container = document.getElementById('cartItemsContainer');
    const grandTotalEl = document.getElementById('cartGrandTotal');

    const totalCount = cart.reduce((sum, item) => sum + item.qty, 0);
    const grandTotal = cart.reduce((sum, item) => sum + (item.price * item.qty), 0);

    if (badge) badge.textContent = totalCount;
    if (grandTotalEl) grandTotalEl.textContent = `₱${grandTotal.toFixed(2)}`;

    if (!container) return;

    if (cart.length === 0) {
        container.innerHTML = `
            <div class="cart-empty-state">
                <i class="fa fa-shopping-basket"></i>
                <p>Your cart is empty.</p>
            </div>`;
        return;
    }

    container.innerHTML = '';
    cart.forEach(item => {
        const itemEl = document.createElement('div');
        itemEl.className = 'cart-item-row';
        itemEl.innerHTML = `
            <div class="cart-item-info">
                <span class="cart-item-title">${escapeHtml(item.name)}</span>
                <span class="cart-item-price">₱${(item.price * item.qty).toFixed(2)}</span>
            </div>
            <div class="cart-item-controls">
                <button type="button" class="qty-btn btn-minus" data-id="${item.id}">-</button>
                <span class="qty-val">${item.qty}</span>
                <button type="button" class="qty-btn btn-plus" data-id="${item.id}">+</button>
                <button type="button" class="btn-remove-item" data-id="${item.id}"><i class="fa fa-trash"></i></button>
            </div>
        `;
        container.appendChild(itemEl);
    });

    container.querySelectorAll('.btn-minus').forEach(btn => {
        btn.onclick = () => updateQuantity(btn.dataset.id, -1);
    });
    container.querySelectorAll('.btn-plus').forEach(btn => {
        btn.onclick = () => updateQuantity(btn.dataset.id, 1);
    });
    container.querySelectorAll('.btn-remove-item').forEach(btn => {
        btn.onclick = () => removeFromCart(btn.dataset.id);
    });
}

function openCartDrawer() {
    document.getElementById('cartDrawer').classList.add('open');
    document.getElementById('cartOverlay').classList.add('open');
}

function closeCartDrawer() {
    document.getElementById('cartDrawer').classList.remove('open');
    document.getElementById('cartOverlay').classList.remove('open');
}

// Render Order History UI
function updateHistoryUI() {
    const container = document.getElementById('historyItemsContainer');
    if (!container) return;

    if (orderHistory.length === 0) {
        container.innerHTML = `
            <div class="cart-empty-state">
                <i class="fa fa-clipboard-list"></i>
                <p>No order history found.</p>
            </div>`;
        return;
    }

    container.innerHTML = '';
    orderHistory.forEach(order => {
        let itemsHtml = order.items.map(i => `<div class="history-sub-item">• ${escapeHtml(i.name)} x ${i.qty} (₱${(i.price * i.qty).toFixed(2)})</div>`).join('');

        const orderEl = document.createElement('div');
        orderEl.className = 'history-card-row';
        orderEl.innerHTML = `
            <div class="history-header-row">
                <span class="history-id">${order.id}</span>
                <span class="history-date">${order.date}</span>
            </div>
            <div class="history-items-list">${itemsHtml}</div>
            <div class="history-total-row">
                <span>Total: <strong>₱${order.total.toFixed(2)}</strong></span>
                <span class="status-badge-sent">Submitted</span>
            </div>
        `;
        container.appendChild(orderEl);
    });
}

function openHistoryDrawer() {
    document.getElementById('historyDrawer').classList.add('open');
    document.getElementById('historyOverlay').classList.add('open');
}

function closeHistoryDrawer() {
    document.getElementById('historyDrawer').classList.remove('open');
    document.getElementById('historyOverlay').classList.remove('open');
}

// Success Modal Control
function showSuccessModal() {
    const modal = document.getElementById('successModalOverlay');
    if (modal) modal.classList.add('open');
}

function closeSuccessModal() {
    const modal = document.getElementById('successModalOverlay');
    if (modal) modal.classList.remove('open');
}

// Checkout & Send via Chat
function handleCheckout(event) {
    if (event) {
        event.preventDefault();
    }

    if (cart.length === 0) {
        alert('Your cart is empty.');
        return;
    }

    let messageText = "";
    let orderSummaryItems = [];

    cart.forEach(item => {
        messageText += `${item.name} x ${item.qty}\n`;
        orderSummaryItems.push({ name: item.name, qty: item.qty, price: item.price });
    });

    messageText = messageText.trim();

    // Save to Order History
    const newOrder = {
        id: 'ORD-' + Math.floor(100000 + Math.random() * 900000),
        date: new Date().toLocaleString(),
        items: orderSummaryItems,
        total: cart.reduce((sum, item) => sum + (item.price * item.qty), 0)
    };

    orderHistory.unshift(newOrder);
    saveOrderHistory();

    // Send via WebSocket and PostBack
    sendPayload(0x03, {
        ClientName: clientName,
        ChatMessage: messageText,
        windowTitle: "Kiosk Store Order"
    });

    const txtMsg = document.querySelector('[id$="TextBox_ChatMessage"]');
    const txtComputer = document.querySelector('[id$="TextBox_ComputerName"]');
    const txtUser = document.querySelector('[id$="TextBox_UserId"]');
    const saveBtn = document.querySelector('[id$="LinkButton_SaveMessage"]');

    if (txtMsg && txtComputer && txtUser && saveBtn) {
        txtMsg.value = messageText;
        txtComputer.value = clientName;
        txtUser.value = userId;

        const checkoutBtn = document.getElementById('checkoutBtn');
        if (checkoutBtn) setButtonLoading(checkoutBtn, true);

        saveBtn.click();
    }

    clearCart();
    closeCartDrawer();
    showSuccessModal();
}

function escapeHtml(str) {
    return str ? String(str).replace(/[&<>"']/g, s => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[s])) : '';
}

// Button Loading State Handler
const activeLoadingButtons = new Set();

function setButtonLoading(btn, isLoading) {
    if (!btn) return;

    if (isLoading) {
        btn.disabled = true;
        btn.classList.add('btn-loading');

        if (!btn.querySelector('.spinner-icon')) {
            const spinner = document.createElement('span');
            spinner.className = 'spinner-icon';
            spinner.innerHTML = `<svg class="spinner-svg" viewBox="0 0 24 24"><circle class="spinner-path" cx="12" cy="12" r="10" fill="none" stroke-width="3"></circle></svg>`;
            btn.insertBefore(spinner, btn.firstChild);
        }
        activeLoadingButtons.add(btn);
    } else {
        btn.disabled = false;
        btn.classList.remove('btn-loading');
        const spinner = btn.querySelector('.spinner-icon');
        if (spinner) spinner.remove();
        activeLoadingButtons.delete(btn);
    }
}

function resetAllLoadingButtons() {
    activeLoadingButtons.forEach(btn => setButtonLoading(btn, false));
    activeLoadingButtons.clear();
    document.querySelectorAll('.btn-loading').forEach(btn => setButtonLoading(btn, false));
}

// Document Bindings
document.addEventListener('DOMContentLoaded', () => {
    connectAgentWS();
    updateCartUI();
    updateHistoryUI();

    document.addEventListener('click', (e) => {
        const addBtn = e.target.closest('.btn-add-cart');
        if (addBtn) {
            const card = addBtn.closest('.ecom-product-card');
            if (card) {
                const id = card.dataset.id;
                const name = card.dataset.name;
                const price = card.dataset.price;
                const stock = card.dataset.stock;
                addToCart(id, name, price, stock, addBtn);
            }
        }

        const targetBtn = e.target.closest('button, .btn-add-cart, .btn-checkout');

        if (targetBtn && !targetBtn.disabled && targetBtn.id !== 'themeToggle' && !targetBtn.classList.contains('no-loading')) {
            setButtonLoading(targetBtn, true);
            setTimeout(() => {
                if (activeLoadingButtons.has(targetBtn)) {
                    setButtonLoading(targetBtn, false);
                }
            }, 300);
        }
    });

    document.getElementById('cartToggle').onclick = openCartDrawer;
    document.getElementById('closeCartBtn').onclick = closeCartDrawer;
    document.getElementById('cartOverlay').onclick = closeCartDrawer;
    document.getElementById('checkoutBtn').onclick = (e) => handleCheckout(e);

    const historyToggle = document.getElementById('historyToggle');
    if (historyToggle) historyToggle.onclick = openHistoryDrawer;

    const closeHistoryBtn = document.getElementById('closeHistoryBtn');
    if (closeHistoryBtn) closeHistoryBtn.onclick = closeHistoryDrawer;

    const historyOverlay = document.getElementById('historyOverlay');
    if (historyOverlay) historyOverlay.onclick = closeHistoryDrawer;

    const clearHistoryBtn = document.getElementById('clearHistoryBtn');
    if (clearHistoryBtn) {
        clearHistoryBtn.onclick = () => {
            if (confirm('Are you sure you want to clear your order history?')) {
                orderHistory = [];
                saveOrderHistory();
            }
        };
    }

    const closeSuccessBtn = document.getElementById('closeSuccessModalBtn');
    if (closeSuccessBtn) closeSuccessBtn.onclick = closeSuccessModal;

    const themeToggle = document.getElementById('themeToggle');
    if (themeToggle) {
        themeToggle.addEventListener('click', function () {
            var currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
            var newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            document.documentElement.setAttribute('data-theme', newTheme);
            localStorage.setItem('theme', newTheme);
            var icon = this.querySelector('i');
            if (icon) icon.className = newTheme === 'dark' ? 'fa fa-sun' : 'fa fa-moon';
        });
    }
});

if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    const prm = Sys.WebForms.PageRequestManager.getInstance();

    prm.add_beginRequest((sender, args) => {
        let postBackElement = args.get_postBackElement();
        if (postBackElement) {
            const btn = postBackElement.closest('button, input[type="submit"], input[type="button"], a, .btn-checkout');
            if (btn) setButtonLoading(btn, true);
        }
    });

    prm.add_endRequest(() => {
        resetAllLoadingButtons();
        updateCartUI();
        updateHistoryUI();
    });
}

document.addEventListener('contextmenu', function (e) {
    e.preventDefault();
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'F12') {
        e.preventDefault();
    }
    if (e.ctrlKey && e.shiftKey && (e.key === 'I' || e.key === 'i' || e.key === 'J' || e.key === 'j' || e.key === 'C' || e.key === 'c')) {
        e.preventDefault();
    }
    if (e.ctrlKey && (e.key === 'U' || e.key === 'u')) {
        e.preventDefault();
    }
});