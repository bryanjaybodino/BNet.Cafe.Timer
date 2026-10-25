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

    var birthdayCreditsInput = document.querySelector('[id$="TextBox_BirthdayCredits"]');
    
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

    // Optional: Auto-fill '0' if left completely blank before submitting
    if (birthdayCreditsInput && birthdayCreditsInput.value.trim() === '') {
        birthdayCreditsInput.value = '0';
    }

    disableSubmitButton();
    return true;
}