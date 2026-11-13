/**
 * Validates the Client Config form fields, disables submit button, and shows loading indicator
 * @returns {boolean} True if valid, false to cancel ASP.NET postback
 */
function ValidateConfig() {
    var intervalInput = document.querySelector('[id$="TextBox_AutoShutDownInterval"]');
    var inputId = intervalInput ? intervalInput.id : 'TextBox_AutoShutDownInterval';

    var minLoginInput = document.querySelector('[id$="TextBox_MinimumLoginTime"]');
    var minLoginId = minLoginInput ? minLoginInput.id : 'TextBox_MinimumLoginTime';

    var minTransferInput = document.querySelector('[id$="TextBox_MinimumTransferTime"]');
    var minTransferId = minTransferInput ? minTransferInput.id : 'TextBox_MinimumTransferTime';

    var openingTimeInput = document.querySelector('[id$="TextBox_OpeningTime"]');
    var openingTimeId = openingTimeInput ? openingTimeInput.id : 'TextBox_OpeningTime';

    var closingTimeInput = document.querySelector('[id$="TextBox_ClosingTime"]');
    var closingTimeId = closingTimeInput ? closingTimeInput.id : 'TextBox_ClosingTime';

    var warningTimeInput = document.querySelector('[id$="TextBox_WarningTime"]');
    var warningTimeId = warningTimeInput ? warningTimeInput.id : 'TextBox_WarningTime';

    var birthdayCreditsInput = document.querySelector('[id$="TextBox_BirthdayCredits"]');

    var isValidInterval = requiredValidation(inputId);
    if (!isValidInterval) {
        ShowAlert('Please enter an auto shutdown interval.');
        return false;
    }

    var isValidMinLogin = requiredValidation(minLoginId);
    if (!isValidMinLogin) {
        ShowAlert('Please enter the minimum login time.');
        return false;
    }

    var isValidMinTransfer = requiredValidation(minTransferId);
    if (!isValidMinTransfer) {
        ShowAlert('Please enter the minimum transfer time.');
        return false;
    }

    var isValidOpeningTime = requiredValidation(openingTimeId);
    if (!isValidOpeningTime) {
        ShowAlert('Please enter the opening time.');
        return false;
    }

    var isValidClosingTime = requiredValidation(closingTimeId);
    if (!isValidClosingTime) {
        ShowAlert('Please enter the closing time.');
        return false;
    }

    var isValidWarningTime = requiredValidation(warningTimeId);
    if (!isValidWarningTime) {
        ShowAlert('Please enter the warning time before closing.');
        return false;
    }

    // Optional: Auto-fill '0' if left completely blank before submitting
    if (birthdayCreditsInput && birthdayCreditsInput.value.trim() === '') {
        birthdayCreditsInput.value = '0';
    }

    disableSubmitButton();
    return true;
}

function disableSubmitButton() {
    var btn = document.querySelector('[id$="LinkButton_Submit"]');
    if (btn) {
        btn.classList.add('disabled');
        btn.style.pointerEvents = 'none';
        btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
    }
}

if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    var prm = Sys.WebForms.PageRequestManager.getInstance();

    // Triggered after UpdatePanel content updates
    prm.add_pageLoaded(function (sender, args) {
        var panelsUpdated = args.get_panelsUpdated();
        if (panelsUpdated.length > 0) {
            // Re-disable button during redirect window if needed
            disableSubmitButton();
        }
    });

    // Triggered when an async postback finishes (success or error)
    prm.add_endRequest(function (sender, args) {
        var btn = document.querySelector('[id$="LinkButton_Submit"]');
        if (btn) {
            btn.classList.remove('disabled');
            btn.style.pointerEvents = 'auto';
            btn.innerHTML = 'Submit'; // Restore original text/HTML
        }
    });
}

// Function to switch active configuration tabs
function switchConfigTab(evt, tabId) {
    var panes = document.querySelectorAll('.config-tab-pane');
    panes.forEach(function (pane) {
        pane.classList.remove('active');
    });

    var buttons = document.querySelectorAll('.config-tab-btn');
    buttons.forEach(function (btn) {
        btn.classList.remove('active');
    });

    var targetPane = document.getElementById(tabId);
    if (targetPane) {
        targetPane.classList.add('active');
    }

    if (evt && evt.currentTarget) {
        evt.currentTarget.classList.add('active');
    }

    // Save active tab ID to the hidden field for postback retention
    var hf = document.querySelector('[id$="hfActiveTab"]');
    if (hf) {
        hf.value = tabId;
    }
}

// Re-bind tab functionality and restore active tab after ASP.NET AJAX UpdatePanel postbacks
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    Sys.WebForms.PageRequestManager.getInstance().add_pageLoaded(function () {
        var hf = document.querySelector('[id$="hfActiveTab"]');
        if (hf && hf.value) {
            var activeTabId = hf.value;
            var targetPane = document.getElementById(activeTabId);

            if (targetPane) {
                document.querySelectorAll('.config-tab-pane').forEach(function (p) { p.classList.remove('active'); });
                document.querySelectorAll('.config-tab-btn').forEach(function (b) { b.classList.remove('active'); });

                targetPane.classList.add('active');

                document.querySelectorAll('.config-tab-btn').forEach(function (btn) {
                    var onClickAttr = btn.getAttribute('onclick');
                    if (onClickAttr && onClickAttr.indexOf(activeTabId) !== -1) {
                        btn.classList.add('active');
                    }
                });
            }
        }
    });
}