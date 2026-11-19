/* =====================================================================
   POS.js
   ===================================================================== */

/* ---------------------------------------------------------------------
   Validation (unchanged behaviour)
   --------------------------------------------------------------------- */
function ValidatePOS() {
    var itemId = document.querySelector('[id$="HiddenField_SelectedItemId"]');
    var qtyInput = document.querySelector('[id$="TextBox_Quantity"]');

    if (!itemId || !itemId.value) {
        alert('Please select an item from the catalog first.');
        return false;
    }

    var qty = qtyInput ? (parseInt(qtyInput.value, 10) || 0) : 0;
    if (qty <= 0) {
        alert('Quantity must be greater than 0.');
        return false;
    }

    disablePOSSubmit();
    return true;
}

function ValidatePOSCart() {
    // Count real cart rows only (the empty-state row has no .cart-row class)
    var cartRows = document.querySelectorAll('[id$="GridView_Cart"] tr.cart-row');

    if (!cartRows || cartRows.length === 0) {
        alert('Please add at least one product to the cart before checking out.');
        return false;
    }

    disablePOSSubmit();
    return true;
}

function disablePOSSubmit() {
    var btn = document.querySelector('[id$="LinkButton_Submit"]');
    if (btn) {
        btn.classList.add('disabled');
        btn.style.pointerEvents = 'none';
        btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Processing Sale...';
    }
}

/* ---------------------------------------------------------------------
   Mobile order sheet (bottom sheet)
   --------------------------------------------------------------------- */
var POS_MOBILE_MAX = 820; // keep in sync with the CSS media query

function isPOSCartOpen() {
    return document.body.classList.contains('pos-cart-open');
}

function setPOSCartOpen(open) {
    document.body.classList.toggle('pos-cart-open', !!open);
    syncPOSSheetAria();
}

function syncPOSSheetAria() {
    var open = isPOSCartOpen();
    var toggles = document.querySelectorAll('.pos-sheet-toggle');
    for (var i = 0; i < toggles.length; i++) {
        toggles[i].setAttribute('aria-expanded', open ? 'true' : 'false');
    }
}

// Called from the markup: onclick="return togglePOSCart();"
function togglePOSCart() {
    setPOSCartOpen(!isPOSCartOpen());
    return false; // never submit / navigate
}
window.togglePOSCart = togglePOSCart;

// Tap on the dimmed backdrop (the ::after of .pos-container) closes the sheet
document.addEventListener('click', function (e) {
    if (isPOSCartOpen() && e.target && e.target.classList && e.target.classList.contains('pos-container')) {
        setPOSCartOpen(false);
    }
});

// Escape closes the sheet
document.addEventListener('keydown', function (e) {
    if ((e.key === 'Escape' || e.keyCode === 27) && isPOSCartOpen()) {
        setPOSCartOpen(false);
    }
});

// Leaving mobile layout (rotate / resize) must not leave the page scroll-locked
window.addEventListener('resize', function () {
    if (window.innerWidth > POS_MOBILE_MAX && isPOSCartOpen()) {
        setPOSCartOpen(false);
    }
});

/* ---------------------------------------------------------------------
   Cart count badge + total "bump" animation
   (derived from the rendered markup, so no backend change is needed)
   --------------------------------------------------------------------- */
var posLastTotal = null;

function updatePOSCartMeta() {
    var badge = document.querySelector('.pos-cart-count');
    if (badge) {
        var qtyEls = document.querySelectorAll('[id$="GridView_Cart"] .qty-value');
        var count = 0;
        for (var i = 0; i < qtyEls.length; i++) {
            count += parseInt(qtyEls[i].textContent, 10) || 0;
        }
        badge.textContent = count > 0 ? count + (count === 1 ? ' item' : ' items') : 'No items';
        badge.classList.toggle('is-empty', count === 0);
    }

    var label = document.querySelector('[id$="Label_Total"]');
    var amount = document.querySelector('.total-amount');
    var value = label ? label.textContent.trim() : null;

    if (amount && value !== null && posLastTotal !== null && value !== posLastTotal) {
        amount.classList.remove('pos-bump');
        void amount.offsetWidth; // restart the animation
        amount.classList.add('pos-bump');
    }
    if (value !== null) {
        posLastTotal = value;
    }
}

/* ---------------------------------------------------------------------
   ASP.NET AJAX hooks (re-run after every partial postback)
   --------------------------------------------------------------------- */
var posPrmBound = false;

function bindPOSRequestManager() {
    if (posPrmBound) return;
    if (typeof Sys === 'undefined' || !Sys.WebForms || !Sys.WebForms.PageRequestManager) return;

    var prm = Sys.WebForms.PageRequestManager.getInstance();
    if (!prm) return;
    posPrmBound = true;

    prm.add_endRequest(function () {
        // Re-enable submit button
        var btn = document.querySelector('[id$="LinkButton_Submit"]');
        if (btn) {
            btn.classList.remove('disabled');
            btn.style.pointerEvents = 'auto';
        }
        // The UpdatePanel re-rendered the sheet toggle: restore state + refresh count
        syncPOSSheetAria();
        updatePOSCartMeta();
    });
}

function initPOS() {
    bindPOSRequestManager();
    syncPOSSheetAria();
    updatePOSCartMeta();
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initPOS);
} else {
    initPOS();
}
// Sys may load after this script; try again once everything is ready
window.addEventListener('load', initPOS);

/* ---------------------------------------------------------------------
   FULL SCREEN MODE (guarded so a missing helper/button can't throw)
   --------------------------------------------------------------------- */
try {
    if (typeof isMobile === 'function' && !isMobile()) {
        var posToggleBtn = document.getElementById('toggleBtn');
        if (posToggleBtn) posToggleBtn.click();
    }
} catch (err) { /* ignore */ }

/* ---------------------------------------------------------------------
   Quantity input helper (unchanged behaviour)
   --------------------------------------------------------------------- */
function handleQuantityInput(input) {
    // 1. Sanitize input to numbers only
    if (typeof NumberOnly === 'function') {
        NumberOnly(input);
    }

    // 2. Trigger calculation logic
    if (typeof calculatePOSReceiptChange === 'function') {
        calculatePOSReceiptChange();
    }
}