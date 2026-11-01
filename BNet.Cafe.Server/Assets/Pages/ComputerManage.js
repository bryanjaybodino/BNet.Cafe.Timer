/**
 * Validates the Computer Create/Edit form fields, disables submit button, and shows loading indicator
 * @returns {boolean} True if valid, false to cancel ASP.NET postback
 */
function Validate() {
    var computerInput = document.querySelector('[id$="TextBox_ComputerName"]');
    var macInput = document.querySelector('[id$="TextBox_MACAddress"]');

    var inputId = computerInput ? computerInput.id : 'TextBox_ComputerName';
    var macId = macInput ? macInput.id : 'TextBox_MACAddress';

    var isValidComputer = requiredValidation(inputId);
    var isValidMac = requiredValidation(macId);

    if (!isValidComputer || !isValidMac) {
        ShowAlert('Please fill in both the computer name and MAC address.');
        return false;
    }

    // Disable button and add loading spinner upon successful client-side validation
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

    prm.add_pageLoaded(function (sender, args) {
        var panelsUpdated = args.get_panelsUpdated();
        if (panelsUpdated.length > 0) {
            disableSubmitButton();
        }
    });

    prm.add_endRequest(function (sender, args) {
        var btn = document.querySelector('[id$="LinkButton_Submit"]');
        if (btn) {
            btn.classList.remove('disabled');
            btn.style.pointerEvents = 'auto';
            btn.innerHTML = 'Submit';
        }
    });
}