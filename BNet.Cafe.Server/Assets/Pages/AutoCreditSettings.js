document.addEventListener('DOMContentLoaded', function () {
    const pointsInput = document.querySelector('[id$="TextBox_Points"]');
    const pointsDisplay = document.getElementById('PointsDisplay');

    function updatePointsDisplay() {
        if (pointsInput && pointsDisplay) {
            const value = parseFloat(pointsInput.value) || 0;
            pointsDisplay.textContent = value.toFixed(2) + ' pts';
        }
    }

    if (pointsInput) {
        pointsInput.addEventListener('input', updatePointsDisplay);
    }

    function bindAutoCreditEvents() {
        if (pointsInput) {
            pointsInput.addEventListener('input', updatePointsDisplay);
        }
        updatePointsDisplay();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_pageLoaded(function () {
            bindAutoCreditEvents();
        });
    }
});

function ValidateAutoCreditRule() {
    var creditNameInput = document.querySelector('[id$="TextBox_CreditName"]');
    var triggerDateInput = document.querySelector('[id$="TextBox_TriggerDate"]');
    var points = document.querySelector('[id$="TextBox_Points"]');
    var customerType = document.querySelector('[id$="DropDownList_CustomerType"]');

    if (!creditNameInput || !creditNameInput.value.trim()) {
        alert('Please enter a credit name.');
        return false;
    }

    if (!customerType || !customerType.value) {
        alert('Please select a customer tier.');
        return false;
    }

    if (!triggerDateInput || !triggerDateInput.value.trim()) {
        alert('Please enter a trigger date or condition.');
        return false;
    }

    if (!points || !points.value || parseFloat(points.value) < 0) {
        alert('Please enter a valid points amount.');
        return false;
    }

    // Trigger the loading spinner animation on the submit button
    disableAutoCreditSubmitButton();
    return true;
}

function editAutoCreditRule(buttonElement) {
    const id = buttonElement.getAttribute('data-id');
    const creditName = buttonElement.getAttribute('data-creditname');
    const tier = buttonElement.getAttribute('data-tier');
    const triggerDate = buttonElement.getAttribute('data-triggerdate');
    const points = buttonElement.getAttribute('data-points');

    const hiddenId = document.querySelector('[id$="HiddenField_AutoCreditId"]');
    const txtCreditName = document.querySelector('[id$="TextBox_CreditName"]');
    const ddlTier = document.querySelector('[id$="DropDownList_CustomerType"]');
    const txtTriggerDate = document.querySelector('[id$="TextBox_TriggerDate"]');
    const txtPoints = document.querySelector('[id$="TextBox_Points"]');
    const btnSubmit = document.querySelector('[id$="LinkButton_Submit"]');

    if (hiddenId) hiddenId.value = id;
    if (txtCreditName) txtCreditName.value = creditName;
    if (ddlTier) ddlTier.value = tier;
    if (txtTriggerDate) txtTriggerDate.value = triggerDate;
    if (txtPoints) txtPoints.value = parseFloat(points).toFixed(2);

    if (btnSubmit) {
        btnSubmit.innerHTML = '<i class="fa fa-save"></i> Update Rate';
    }

    if (txtPoints) txtPoints.dispatchEvent(new Event('input'));
}

function disableAutoCreditSubmitButton() {
    var btn = document.querySelector('[id$="LinkButton_Submit"]');
    if (btn) {
        btn.classList.add('disabled');
        btn.style.pointerEvents = 'none';
        btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
    }
}

// Restore button state after the ASP.NET AJAX UpdatePanel postback finishes
if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    var prm = Sys.WebForms.PageRequestManager.getInstance();

    prm.add_endRequest(function (sender, args) {
        var btn = document.querySelector('[id$="LinkButton_Submit"]');
        if (btn) {
            btn.classList.remove('disabled');
            btn.style.pointerEvents = 'auto';
            btn.innerHTML = '<i class="fa fa-save"></i> Save Rate';
        }
    });
}