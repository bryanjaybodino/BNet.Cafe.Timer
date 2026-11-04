// Asynchronously fetch exact duration calculation from the backend ASHX Handler based on amount
function CalculateDurationFromAmountHandlerBackend(amount, baseMinutes) {
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');
    var timeBreakdown = document.getElementById('display_TimeBreakdown');

    if (!amount || amount <= 0) {
        if (baseMinutes > 0) {
            if (durationInput) durationInput.value = '';
            if (displayTime) displayTime.innerText = formatTime(baseMinutes);
            if (timeBreakdown) timeBreakdown.style.display = 'none';
        } else {
            if (displayTime) displayTime.innerText = "0 hrs 0 mins";
            if (displayAmount) displayAmount.innerText = "₱ 0.00";
            if (durationInput) durationInput.value = "";
        }
        return;
    }

    var customerType = getCustomerType();

    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx');

    fetch(endpoint + '?amount=' + amount + '&customerType=' + encodeURIComponent(customerType))
        .then(function (response) {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(function (data) {
            if (data) {
                var extraMinutes = data.totalMinutes || 0;
                var totalMinutes = baseMinutes + extraMinutes;

                if (durationInput) {
                    durationInput.value = extraMinutes > 0 ? extraMinutes : '';
                }

                if (displayTime) {
                    displayTime.innerText = formatTime(totalMinutes);
                }

                if (displayAmount) {
                    displayAmount.innerText = data.formattedAmount;
                }

                if (timeBreakdown && baseMinutes > 0) {
                    if (extraMinutes > 0) {
                        timeBreakdown.innerText = 'Base: ' + formatTime(baseMinutes) + ' | Extra: +' + formatTime(extraMinutes);
                        timeBreakdown.style.display = 'block';
                    } else {
                        timeBreakdown.style.display = 'none';
                    }
                }
            }
        })
        .catch(function (error) {
            console.error('Error fetching calculated duration from handler:', error);
        });
}

function formatTime(mins) {
    var h = Math.floor(mins / 60);
    var m = mins % 60;
    if (h > 0 && m > 0) return h + ' hrs ' + m + ' mins';
    if (h > 0) return h + ' hrs';
    return m + ' mins';
}

// Automatically compute duration when Admin manually inputs/changes the Amount (Treating input as Extra Amount)
function calculateTimeFromAmount() {
    var amountInput = document.querySelector('[id$="TextBox_Amount"]');
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');
    var initialDurationInput = document.querySelector('[id$="HiddenField_InitialDuration"]');
    var initialAmountInput = document.querySelector('[id$="HiddenField_InitialAmount"]');

    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');
    var timeBreakdown = document.getElementById('display_TimeBreakdown');
    var amountBreakdown = document.getElementById('display_AmountBreakdown');

    if (!amountInput) return;

    var initialMinutes = initialDurationInput ? (parseInt(initialDurationInput.value, 10) || 0) : 0;
    var initialAmount = initialAmountInput ? (parseFloat(initialAmountInput.value) || 0) : 0;

    var extraAmountInput = parseFloat(amountInput.value);
    var extraAmount = isNaN(extraAmountInput) ? 0 : extraAmountInput;

    if (extraAmount < 0) extraAmount = 0;

    var totalAmount = initialAmount + extraAmount;

    if (extraAmount > 0) {
        var customerType = getCustomerType();

        var endpoint = /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx');

        fetch(endpoint + '?amount=' + extraAmount + '&customerType=' + encodeURIComponent(customerType))
            .then(function (response) {
                if (!response.ok) throw new Error('Network response was not ok');
                return response.json();
            })
            .then(function (data) {
                if (data) {
                    var extendedMinutes = data.totalMinutes || 0;
                    var totalMinutes = initialMinutes + extendedMinutes;

                    // Populate TextBox_Duration with the calculated extra minutes
                    if (durationInput) {
                        durationInput.value = extendedMinutes > 0 ? extendedMinutes : '';
                    }

                    if (displayTime) displayTime.innerText = formatTime(totalMinutes);
                    if (displayAmount) displayAmount.innerText = '₱ ' + totalAmount.toFixed(2);

                    if (totalAmountField) totalAmountField.value = totalAmount.toFixed(2);
                    if (totalDurationField) totalDurationField.value = totalMinutes;

                    if (initialMinutes > 0) {
                        if (timeBreakdown) {
                            timeBreakdown.innerText = 'Base: ' + formatTime(initialMinutes) + ' | Extra: +' + formatTime(extendedMinutes);
                            timeBreakdown.style.display = 'block';
                        }
                        if (amountBreakdown) {
                            amountBreakdown.innerText = '(Prepaid: ₱' + initialAmount.toFixed(2) + ' + Extra: ₱' + extraAmount.toFixed(2) + ')';
                            amountBreakdown.style.display = 'block';
                        }
                    } else {
                        if (timeBreakdown) timeBreakdown.style.display = 'none';
                        if (amountBreakdown) amountBreakdown.style.display = 'none';
                    }
                }
            })
            .catch(function (error) {
                console.error('Error fetching calculated duration from handler:', error);
            });
    } else {
        if (durationInput) durationInput.value = '';
        if (displayTime) displayTime.innerText = formatTime(initialMinutes);
        if (displayAmount) displayAmount.innerText = '₱ ' + initialAmount.toFixed(2);

        if (totalAmountField) totalAmountField.value = initialAmount.toFixed(2);
        if (totalDurationField) totalDurationField.value = initialMinutes;

        if (timeBreakdown) timeBreakdown.style.display = 'none';
        if (amountBreakdown) amountBreakdown.style.display = 'none';
    }
}

// Asynchronously fetch exact rate calculation from the backend ASHX Handler
function calculateRentalPriceBackend(totalMinutes) {
    var amountInput = document.querySelector('[id$="TextBox_Amount"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');
    var initialDurationInput = document.querySelector('[id$="HiddenField_InitialDuration"]');
    var initialAmountInput = document.querySelector('[id$="HiddenField_InitialAmount"]');

    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');

    var initialMinutes = initialDurationInput ? (parseInt(initialDurationInput.value, 10) || 0) : 0;
    var initialAmount = initialAmountInput ? (parseFloat(initialAmountInput.value) || 0) : 0;

    var extraMinutes = totalMinutes;
    var finalMinutes = initialMinutes + extraMinutes;

    if (!extraMinutes || extraMinutes <= 0) {
        var baseTotalMin = initialMinutes;
        if (displayTime) displayTime.innerText = formatTime(baseTotalMin);
        if (displayAmount) displayAmount.innerText = "₱ " + initialAmount.toFixed(2);
        if (amountInput) amountInput.value = "";
        if (totalAmountField) totalAmountField.value = initialAmount.toFixed(2);
        if (totalDurationField) totalDurationField.value = baseTotalMin;
        return;
    }

    if (totalDurationField) totalDurationField.value = finalMinutes;

    var customerType = getCustomerType();

    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx');

    fetch(endpoint + '?minutes=' + extraMinutes + '&customerType=' + encodeURIComponent(customerType))
        .then(function (response) {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(function (data) {
            if (data) {
                var extensionCharge = data.totalAmount || 0;
                var totalCharge = initialAmount + extensionCharge;

                if (displayTime) {
                    displayTime.innerText = formatTime(finalMinutes);
                }

                if (displayAmount) {
                    displayAmount.innerText = '₱ ' + totalCharge.toFixed(2);
                }

                if (amountInput) {
                    amountInput.value = extensionCharge.toFixed(2);
                }

                if (totalAmountField) {
                    totalAmountField.value = totalCharge.toFixed(2);
                }
            }
        })
        .catch(function (error) {
            console.error('Error fetching calculated price from handler:', error);
        });
}

// Calculate amount and handle breakdown display
function calculateAmount() {
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');
    var initialDurationInput = document.querySelector('[id$="HiddenField_InitialDuration"]');
    var initialAmountInput = document.querySelector('[id$="HiddenField_InitialAmount"]');
    var amountInput = document.querySelector('[id$="TextBox_Amount"]');

    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');
    var timeBreakdown = document.getElementById('display_TimeBreakdown');
    var amountBreakdown = document.getElementById('display_AmountBreakdown');

    if (!durationInput) return;

    var initialMinutes = initialDurationInput ? (parseInt(initialDurationInput.value, 10) || 0) : 0;
    var initialAmount = initialAmountInput ? (parseFloat(initialAmountInput.value) || 0) : 0;

    var extraMinutesInput = parseInt(durationInput.value, 10);
    var extraMinutes = isNaN(extraMinutesInput) ? 0 : extraMinutesInput;

    if (extraMinutes < 0) extraMinutes = 0;

    var totalMinutes = initialMinutes + extraMinutes;

    function formatTime(mins) {
        var h = Math.floor(mins / 60);
        var m = mins % 60;
        if (h > 0 && m > 0) return h + ' hrs ' + m + ' mins';
        if (h > 0) return h + ' hrs';
        return m + ' mins';
    }

    if (displayTime) displayTime.innerText = formatTime(totalMinutes);
    if (totalDurationField) totalDurationField.value = totalMinutes;

    if (extraMinutes === 0) {
        if (amountInput) amountInput.value = '';
        if (displayAmount) displayAmount.innerText = '₱ ' + initialAmount.toFixed(2);

        if (totalAmountField) totalAmountField.value = initialAmount.toFixed(2);
        if (totalDurationField) totalDurationField.value = initialMinutes;

        if (timeBreakdown) timeBreakdown.style.display = 'none';
        if (amountBreakdown) amountBreakdown.style.display = 'none';
        return;
    }

    var customerType = getCustomerType();

    var endpoint = /\.aspx$/i.test(window.location.pathname)
        ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx')
        : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx');

    fetch(endpoint + '?minutes=' + extraMinutes + '&customerType=' + encodeURIComponent(customerType))
        .then(function (response) { return response.json(); })
        .then(function (data) {
            if (data) {
                var extensionCharge = data.totalAmount;
                var totalCharge = initialAmount + extensionCharge;

                if (amountInput) amountInput.value = extensionCharge.toFixed(2);
                if (displayAmount) displayAmount.innerText = '₱ ' + totalCharge.toFixed(2);

                if (totalAmountField) totalAmountField.value = totalCharge.toFixed(2);
                if (totalDurationField) totalDurationField.value = totalMinutes;

                if (initialMinutes > 0) {
                    if (timeBreakdown) {
                        timeBreakdown.innerText = 'Base: ' + formatTime(initialMinutes) + ' | Extra: +' + formatTime(extraMinutes);
                        timeBreakdown.style.display = 'block';
                    }
                    if (amountBreakdown) {
                        amountBreakdown.innerText = '(Prepaid: ₱' + initialAmount.toFixed(2) + ' + Extra: ₱' + extensionCharge.toFixed(2) + ')';
                        amountBreakdown.style.display = 'block';
                    }
                } else {
                    if (timeBreakdown) timeBreakdown.style.display = 'none';
                    if (amountBreakdown) amountBreakdown.style.display = 'none';
                }
            }
        })
        .catch(function (err) { console.error(err); });
}

function adjustDuration(amount) {
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    if (!durationInput) return;

    var currentExtra = parseInt(durationInput.value, 10) || 0;
    var updated = currentExtra + amount;

    if (updated < 0) {
        updated = 0;
    }

    durationInput.value = updated > 0 ? updated : '';
    calculateAmount();
}

// Reset button clears extra inputs and reverts back to initial base values
function resetDuration() {
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    var amountInput = document.querySelector('[id$="TextBox_Amount"]');
    var initialDurationInput = document.querySelector('[id$="HiddenField_InitialDuration"]');
    var initialAmountInput = document.querySelector('[id$="HiddenField_InitialAmount"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');

    var initialMinutes = initialDurationInput ? (parseInt(initialDurationInput.value, 10) || 0) : 0;
    var initialAmount = initialAmountInput ? (parseFloat(initialAmountInput.value, 10) || 0) : 0;

    if (durationInput) durationInput.value = '';
    if (amountInput) amountInput.value = '';

    if (totalDurationField) totalDurationField.value = initialMinutes;
    if (totalAmountField) totalAmountField.value = initialAmount.toFixed(2);

    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');
    var timeBreakdown = document.getElementById('display_TimeBreakdown');
    var amountBreakdown = document.getElementById('display_AmountBreakdown');

    if (displayTime) displayTime.innerText = formatTime(initialMinutes);
    if (displayAmount) displayAmount.innerText = '₱ ' + initialAmount.toFixed(2);

    if (timeBreakdown) timeBreakdown.style.display = 'none';
    if (amountBreakdown) amountBreakdown.style.display = 'none';
}

// Client validation before submission
function Validate() {
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');

    var errors = [];

    if (!totalDurationField || parseInt(totalDurationField.value, 10) <= 0) {
        errors.push('Please select or input a valid duration.');
    }

    if (!totalAmountField || parseFloat(totalAmountField.value) <= 0) {
        errors.push('Calculated amount must be greater than 0.');
    }

    if (errors.length > 0) {
        if (typeof ShowAlert === 'function') {
            ShowAlert(errors);
        } else {
            alert(errors.join('\n'));
        }
        return false;
    }
    disableSubmitButton();
    return true;
}

function getCustomerType() {
    var customerType = document.querySelector('[id$="HiddenField_Role"]');
    return customerType ? customerType.value.toUpperCase() : 'GUEST';
}

function disableSubmitButton() {
    var btn = document.querySelector('[id$="LinkButton_Submit"]');
    if (btn) {
        btn.classList.add('disabled');
        btn.style.pointerEvents = 'none';
        btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
    }
}

function initRentalForm() {
    var initialDurationInput = document.querySelector('[id$="HiddenField_InitialDuration"]');
    var initialAmountInput = document.querySelector('[id$="HiddenField_InitialAmount"]');
    var totalAmountField = document.querySelector('[id$="TextBox_TotalAmount"]');
    var totalDurationField = document.querySelector('[id$="TextBox_TotalDuration"]');
    var durationInput = document.querySelector('[id$="TextBox_Duration"]');
    var amountInput = document.querySelector('[id$="TextBox_Amount"]');

    var displayTime = document.getElementById('display_FormattedTime');
    var displayAmount = document.getElementById('display_TotalAmount');

    var initialMinutes = initialDurationInput ? (parseInt(initialDurationInput.value, 10) || 0) : 0;
    var initialAmount = initialAmountInput ? (parseFloat(initialAmountInput.value, 10) || 0) : 0;

    if (durationInput) durationInput.value = '';
    if (amountInput) amountInput.value = '';

    if (totalDurationField) totalDurationField.value = initialMinutes;
    if (totalAmountField) totalAmountField.value = initialAmount.toFixed(2);

    if (displayTime) displayTime.innerText = formatTime(initialMinutes);
    if (displayAmount) displayAmount.innerText = '₱ ' + initialAmount.toFixed(2);
}

if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
    var prm = Sys.WebForms.PageRequestManager.getInstance();

    prm.add_pageLoaded(function (sender, args) {
        var panelsUpdated = args.get_panelsUpdated();
        if (panelsUpdated.length > 0) {
            disableSubmitButton();
            initRentalForm();
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

document.addEventListener('DOMContentLoaded', () => {
    initRentalForm();
});