<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteLogout.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteLogout" %>
<asp:HiddenField ID="HiddenField_LogoutId" runat="server" />
<asp:HiddenField ID="HiddenField_LogoutClientId" runat="server" />
<asp:HiddenField ID="HiddenField_IsOpenTime" runat="server" />
<asp:HiddenField ID="HiddenField_LogoutAmount" runat="server" />
<asp:HiddenField ID="HiddenField_LogoutTotalMinutes" runat="server" />

<!-- BNet Modal Template -->
<div id="logoutModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Confirm Logout</h3>
            <span class="bnet-modal-close" onclick="closeLogoutModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Are you sure you want to logout computer <strong id="logoutTargetName"></strong>?</p>
            <div id="logoutBillingSummary" style="margin-top: 12px; padding: 12px 14px; border-radius: 6px; background: var(--bg-secondary, rgba(0,0,0,0.04)); font-size: 13px;">
                <div><strong>Session Type:</strong> <span id="logoutSessionType">-</span></div>
                <div style="margin-top: 4px;"><strong>Total Hours:</strong> <span id="logoutTotalHours">-</span></div>
                <div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid rgba(0,0,0,0.08);">
                    <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 0.4px; opacity: 0.8;">Amount to Pay</div>
                    <strong id="logoutTotalAmount" style="display: block; margin-top: 2px; font-size: 28px; line-height: 1.2; font-weight: 700;">₱0.00</strong>
                </div>
            </div>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 8px;">This action cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeLogoutModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmLogout" OnClientClick="disableLogoutButton()" OnClick="LinkButton_ConfirmLogout_Click" CssClass="btn btn-danger" runat="server">Logout</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    // Global instance tracker
    let logoutModalInstance = null;

    function getLogoutModal() {
        if (!logoutModalInstance) {
            logoutModalInstance = new BNetModal('#logoutModal');
        }
        return logoutModalInstance;
    }

    function getLogoutCustomerType(roleAttr) {
        var normalized = (roleAttr || '').toUpperCase().trim();
        if (normalized.indexOf('VIP') !== -1) return 'VIP';
        if (normalized.indexOf('MEMBER') !== -1) return 'MEMBER';
        return 'GUEST / WALK-IN';
    }

    function getLogoutCalculateEndpoint() {
        return /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx');
    }

    function formatLogoutDuration(totalMinutes) {
        var safeMinutes = Math.max(0, Math.floor(totalMinutes));
        var hours = Math.floor(safeMinutes / 60);
        var mins = safeMinutes % 60;
        var hrLabel = hours === 1 ? 'hr' : 'hrs';
        var minLabel = mins === 1 ? 'min' : 'mins';

        if (hours > 0 && mins > 0) return hours + ' ' + hrLabel + ' ' + mins + ' ' + minLabel;
        if (hours > 0) return hours + ' ' + hrLabel;
        return mins + ' ' + minLabel;
    }

    function computeOpenTimeMinutes(row) {
        var timeStartLabel = row ? row.querySelector('[id*="Label_TimeStart"]') : null;
        var rawStart = timeStartLabel ? (timeStartLabel.getAttribute('data-raw-start') || '') : '';
        var startDate = rawStart ? new Date(rawStart) : null;

        if (startDate && !isNaN(startDate.getTime())) {
            var nowMs = Date.now();
            var diffMinutes = Math.max(0, Math.floor((nowMs - startDate.getTime()) / 60000));
            return {
                totalMinutes: diffMinutes,
                endDate: new Date(nowMs)
            };
        }

        var runningTimer = row ? row.querySelector('.running-timer') : null;
        var timerText = runningTimer ? (runningTimer.innerText || runningTimer.textContent).trim() : '';
        var parts = timerText.split(':');
        if (parts.length === 3) {
            var h = parseInt(parts[0], 10) || 0;
            var m = parseInt(parts[1], 10) || 0;
            var s = parseInt(parts[2], 10) || 0;
            var totalSecs = (h * 3600) + (m * 60) + s;
            return {
                totalMinutes: Math.max(0, Math.floor(totalSecs / 60)),
                endDate: new Date()
            };
        }

        return { totalMinutes: 0, endDate: new Date() };
    }

    function openLogoutModal(element, id, name) {
        var row = element ? element.closest('tr') : null;
        var timeEndLabel = row ? row.querySelector('[id*="Label_TimeEnd"]') : null;
        var billingLabel = row ? row.querySelector('[id*="Label_Billing"]') : null;
        var totalHoursLabel = row ? row.querySelector('[id*="Label_TotalHours"]') : null;

        var timeEndValue = timeEndLabel ? (timeEndLabel.innerText || timeEndLabel.textContent).trim() : '';
        var isOpenTime = (timeEndValue === '∞');

        var amountField = document.getElementById('<%= HiddenField_LogoutAmount.ClientID %>');
        var minutesField = document.getElementById('<%= HiddenField_LogoutTotalMinutes.ClientID %>');
        var sessionTypeEl = document.getElementById('logoutSessionType');
        var totalHoursEl = document.getElementById('logoutTotalHours');
        var totalAmountEl = document.getElementById('logoutTotalAmount');

        document.getElementById('<%= HiddenField_LogoutId.ClientID %>').value = id;
        document.getElementById('<%= HiddenField_LogoutClientId.ClientID %>').value = name;
        document.getElementById('<%= HiddenField_IsOpenTime.ClientID %>').value = isOpenTime.toString().toUpperCase();
        document.getElementById('logoutTargetName').innerText = name;

        if (isOpenTime) {
            var openCalc = computeOpenTimeMinutes(row);
            var extraMinutes = openCalc.totalMinutes;
            var formattedHours = formatLogoutDuration(extraMinutes);
            var customerType = getLogoutCustomerType(billingLabel ? billingLabel.getAttribute('data-role') : '');
            var endpoint = getLogoutCalculateEndpoint();

            if (sessionTypeEl) sessionTypeEl.innerText = 'Open Time (∞)';
            if (totalHoursEl) totalHoursEl.innerText = formattedHours;
            if (totalAmountEl) totalAmountEl.innerText = 'Calculating...';
            if (minutesField) minutesField.value = extraMinutes;
            if (amountField) amountField.value = '0.00';

            fetch(endpoint + '?minutes=' + encodeURIComponent(extraMinutes) + '&customerType=' + encodeURIComponent(customerType) + '&clientName=' + encodeURIComponent(name))
                .then(function (response) { return response.json(); })
                .then(function (data) {
                    var computedAmount = (data && typeof data.totalAmount !== 'undefined') ? Number(data.totalAmount) : 0;
                    if (isNaN(computedAmount)) computedAmount = 0;

                    if (amountField) amountField.value = computedAmount.toFixed(2);
                    if (minutesField && data && typeof data.totalMinutes !== 'undefined') {
                        minutesField.value = data.totalMinutes;
                    }
                    if (totalHoursEl && data && data.formattedTime) {
                        totalHoursEl.innerText = data.formattedTime;
                    }
                    if (totalAmountEl) {
                        totalAmountEl.innerText = (data && data.formattedAmount) ? data.formattedAmount : ('₱' + computedAmount.toFixed(2));
                    }
                })
                .catch(function () {
                    var fallbackBilling = billingLabel ? (billingLabel.innerText || billingLabel.textContent).trim() : '₱0.00';
                    var numericFallback = parseFloat(fallbackBilling.replace(/[^0-9.-]+/g, '')) || 0;
                    if (amountField) amountField.value = numericFallback.toFixed(2);
                    if (totalAmountEl) totalAmountEl.innerText = fallbackBilling || '₱0.00';
                });
        } else {
            var regularBillingText = billingLabel ? (billingLabel.innerText || billingLabel.textContent).trim() : '₱0.00';
            var regularHoursText = totalHoursLabel ? (totalHoursLabel.innerText || totalHoursLabel.textContent).trim() : '-';
            var regularNumeric = parseFloat(regularBillingText.replace(/[^0-9.-]+/g, '')) || 0;

            if (sessionTypeEl) sessionTypeEl.innerText = 'Regular Time';
            if (totalHoursEl) totalHoursEl.innerText = regularHoursText;
            if (totalAmountEl) totalAmountEl.innerText = regularBillingText;
            if (minutesField) minutesField.value = '0';
            if (amountField) amountField.value = regularNumeric.toFixed(2);
        }

        getLogoutModal().open();
    }

    function closeLogoutModal() {
        getLogoutModal().close();
    }

    // Re-initialize modal reference on ASP.NET AJAX Partial PostBacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            logoutModalInstance = new BNetModal('#logoutModal');
        });
    }

    function disableLogoutButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmLogout"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
        }
    }
</script>