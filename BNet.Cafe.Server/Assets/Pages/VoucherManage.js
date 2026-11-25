'use strict';

function getVoucherControl(suffix) {
    var form = document.getElementById('MainForm');
    if (form) {
        var matches = form.querySelectorAll('[id$="_' + suffix + '"]');
        if (matches && matches.length > 0) {
            return matches[0];
        }
    }
    var fallback = document.querySelector('[id$="_' + suffix + '"]');
    return fallback || null;
}

function getVoucherEndpoint(handlerFileName) {
    return /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/' + handlerFileName)
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/' + handlerFileName);
}

function getVoucherCustomerType() {
    var roleEl = getVoucherControl('HiddenField_Role');
    return roleEl && roleEl.value ? roleEl.value.toUpperCase() : 'GUEST';
}

function getVoucherClientName() {
    var clientEl = getVoucherControl('HiddenField_ClientName');
    return clientEl ? clientEl.value.trim() : '';
}

function formatVoucherTime(mins) {
    var m = Math.max(0, parseInt(mins, 10) || 0);
    var h = Math.floor(m / 60);
    var rem = m % 60;
    if (h > 0 && rem > 0) return h + ' hrs ' + rem + ' mins';
    if (h > 0) return h + ' hrs';
    return rem + ' mins';
}

function syncVoucherSummary(totalMins, totalAmount) {
    var mins = Math.max(0, parseInt(totalMins, 10) || 0);
    var amt = Math.max(0, parseFloat(totalAmount) || 0);

    var timeEl = document.getElementById('display_VoucherFormattedTime');
    var amtEl = document.getElementById('display_VoucherTotalAmount');
    var totalDurBox = getVoucherControl('TextBox_TotalDuration');
    var totalAmtBox = getVoucherControl('TextBox_TotalAmount');

    if (timeEl) timeEl.innerText = formatVoucherTime(mins);
    if (amtEl) amtEl.innerText = '₱ ' + amt.toFixed(2);
    if (totalDurBox) totalDurBox.value = mins;
    if (totalAmtBox) totalAmtBox.value = amt.toFixed(2);
}

function calculateVoucherAmount() {
    var durInput = getVoucherControl('TextBox_Duration');
    var amtInput = getVoucherControl('TextBox_Amount');
    if (!durInput) return;

    var mins = parseInt(durInput.value, 10);
    if (isNaN(mins) || mins < 0) mins = 0;

    if (mins === 0) {
        if (amtInput) amtInput.value = '';
        syncVoucherSummary(0, 0);
        return;
    }

    var endpoint = getVoucherEndpoint('CalculateAmountFromDurationHandler.ashx');
    var url = endpoint +
        '?minutes=' + encodeURIComponent(mins) +
        '&customerType=' + encodeURIComponent(getVoucherCustomerType()) +
        '&clientName=' + encodeURIComponent(getVoucherClientName());

    fetch(url)
        .then(function (response) {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        })
        .then(function (data) {
            if (data) {
                var charge = parseFloat(data.totalAmount) || 0;
                if (amtInput) amtInput.value = charge.toFixed(2);
                syncVoucherSummary(mins, charge);
            }
        })
        .catch(function (error) {
            console.error('Error fetching calculated voucher amount from handler:', error);
        });
}

function calculateVoucherTimeFromAmount() {
    var durInput = getVoucherControl('TextBox_Duration');
    var amtInput = getVoucherControl('TextBox_Amount');
    if (!amtInput) return;

    var amt = parseFloat(amtInput.value);
    if (isNaN(amt) || amt < 0) amt = 0;

    if (amt === 0) {
        if (durInput) durInput.value = '';
        syncVoucherSummary(0, 0);
        return;
    }

    var endpoint = getVoucherEndpoint('CalculateDurationFromAmountHandler.ashx');
    var url = endpoint +
        '?amount=' + encodeURIComponent(amt) +
        '&customerType=' + encodeURIComponent(getVoucherCustomerType()) +
        '&clientName=' + encodeURIComponent(getVoucherClientName());

    fetch(url)
        .then(function (response) {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.json();
        })
        .then(function (data) {
            if (data) {
                var mins = parseInt(data.totalMinutes, 10) || 0;
                if (durInput) durInput.value = mins > 0 ? mins : '';
                syncVoucherSummary(mins, amt);
            }
        })
        .catch(function (error) {
            console.error('Error fetching calculated voucher duration from handler:', error);
        });
}

function adjustVoucherDuration(deltaMins) {
    var durInput = getVoucherControl('TextBox_Duration');
    if (!durInput) return;

    var current = parseInt(durInput.value, 10) || 0;
    var next = Math.max(0, current + (parseInt(deltaMins, 10) || 0));
    durInput.value = next > 0 ? next : '';
    calculateVoucherAmount();
}

function resetVoucherDuration() {
    var durInput = getVoucherControl('TextBox_Duration');
    var amtInput = getVoucherControl('TextBox_Amount');
    if (durInput) durInput.value = '';
    if (amtInput) amtInput.value = '';
    syncVoucherSummary(0, 0);
}

function validateVoucherForm() {
    var totalDurBox = getVoucherControl('TextBox_TotalDuration');
    var totalAmtBox = getVoucherControl('TextBox_TotalAmount');
    var durInput = getVoucherControl('TextBox_Duration');

    var mins = totalDurBox ? (parseInt(totalDurBox.value, 10) || 0) : 0;
    if (mins <= 0 && durInput) {
        mins = parseInt(durInput.value, 10) || 0;
    }

    var amt = totalAmtBox ? (parseFloat(totalAmtBox.value) || 0) : 0;
    var errors = [];

    if (mins <= 0) {
        errors.push('Please enter or select a valid duration.');
    }
    if (amt <= 0) {
        errors.push('Calculated amount must be greater than 0.');
    }

    if (errors.length > 0) {
        if (typeof ShowAlert === 'function') {
            ShowAlert(errors);
        }
        if (durInput && mins <= 0) durInput.focus();
        return false;
    }

    return true;
}

function showCopyPopup(anchorEl, message, isError) {
    var target = anchorEl || (document.activeElement && document.activeElement.closest ? document.activeElement.closest('.copy-anchor, button, a') : null);
    if (!target) return;

    var container = target.classList && target.classList.contains('copy-anchor')
        ? target
        : (target.closest ? target.closest('.copy-anchor') : null);

    if (!container) {
        container = target;
        if (!container.style.position) {
            container.style.position = 'relative';
        }
    }

    var existing = container.querySelector('.copy-popup');
    if (existing) {
        if (existing._hideTimer) clearTimeout(existing._hideTimer);
        existing.remove();
    }

    var popup = document.createElement('span');
    popup.className = 'copy-popup' + (isError ? ' is-error' : '');
    popup.textContent = message;
    container.appendChild(popup);

    requestAnimationFrame(function () {
        popup.classList.add('show');
    });

    popup._hideTimer = setTimeout(function () {
        popup.classList.remove('show');
        setTimeout(function () {
            if (popup.parentNode) popup.parentNode.removeChild(popup);
        }, 180);
    }, 1500);
}

function copyVoucherCode(code, triggerEl) {
    if (!code) return;
    var cleanCode = String(code);
    var btn = triggerEl || (window.event && window.event.currentTarget) || null;

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(cleanCode).then(function () {
            showCopyPopup(btn, 'Copied!', false);
        }, function () {
            fallbackCopyVoucherText(cleanCode, btn);
        });
    } else {
        fallbackCopyVoucherText(cleanCode, btn);
    }
}

function fallbackCopyVoucherText(text, triggerEl) {
    var temp = document.createElement('textarea');
    temp.value = text;
    temp.setAttribute('readonly', '');
    temp.style.position = 'fixed';
    temp.style.opacity = '0';
    document.body.appendChild(temp);
    temp.select();
    try {
        var copied = document.execCommand('copy');
        showCopyPopup(triggerEl, copied ? 'Copied!' : 'Failed', !copied);
    } catch (e) {
        showCopyPopup(triggerEl, 'Failed', true);
    }
    document.body.removeChild(temp);
}

window.calculateVoucherAmount = calculateVoucherAmount;
window.calculateVoucherTimeFromAmount = calculateVoucherTimeFromAmount;
window.adjustVoucherDuration = adjustVoucherDuration;
window.resetVoucherDuration = resetVoucherDuration;
window.validateVoucherForm = validateVoucherForm;
window.copyVoucherCode = copyVoucherCode;

function initVoucherManage() {
    var durInput = getVoucherControl('TextBox_Duration');
    var amtInput = getVoucherControl('TextBox_Amount');
    if (durInput) durInput.value = '';
    if (amtInput) amtInput.value = '';
    syncVoucherSummary(0, 0);
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initVoucherManage);
} else {
    initVoucherManage();
}

if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
        initVoucherManage();
    });
}