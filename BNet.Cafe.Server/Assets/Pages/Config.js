/**
 * Validates the Client Config form fields, disables submit button, and shows loading indicator
 * @returns {boolean} True if valid, false to cancel ASP.NET postback
 */
function ValidateConfig() {
    var intervalInput = document.querySelector('[id$="TextBox_AutoShutDownInterval"]');
    var inputId = intervalInput ? intervalInput.id : 'TextBox_AutoShutDownInterval';

    var openingTimeInput = document.querySelector('[id$="TextBox_OpeningTime"]');
    var openingTimeId = openingTimeInput ? openingTimeInput.id : 'TextBox_OpeningTime';

    var closingTimeInput = document.querySelector('[id$="TextBox_ClosingTime"]');
    var closingTimeId = closingTimeInput ? closingTimeInput.id : 'TextBox_ClosingTime';

    var warningTimeInput = document.querySelector('[id$="TextBox_WarningTime"]');
    var warningTimeId = warningTimeInput ? warningTimeInput.id : 'TextBox_WarningTime';

    var isValidInterval = requiredValidation(inputId);
    if (!isValidInterval) {
        ShowAlert('Please enter an auto shutdown interval.');
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
            btn.innerHTML = '<i class="fa fa-save"></i> Save Configuration'; // Restore original button state
        }
    });
}