<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteEditTime.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteEditTime" %>

<!-- Hidden fields to preserve state inside modal -->
<asp:HiddenField ID="HiddenField_ModalRentalId" runat="server" />

<!-- BNet Modal Template: removed onclick from overlay so clicking outside does not close it -->
<div id="remoteEditTimeModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container" style="width: 420px;" onclick="event.stopPropagation()">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Correct Initial Entry</h3>
            <span class="bnet-modal-close" onclick="closeRemoteEditTimeModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p style="margin-bottom: 16px; color: var(--text-light-secondary); font-size: 13px;">
                Modify the initial duration and amount if a mistake was made.
            </p>

            <div class="form-group" style="margin-bottom: 12px;">
                <label for="<%= TextBox_ModalDuration.ClientID %>">Initial Duration (Minutes)</label>
                <asp:TextBox ID="TextBox_ModalDuration" runat="server" CssClass="form-control" TextMode="Number" min="0" placeholder="e.g., 120 (for 2 hrs)" oninput="syncModalAmountFromDuration()"></asp:TextBox>
            </div>

            <div class="form-group" style="margin-bottom: 8px;">
                <label for="<%= TextBox_ModalAmount.ClientID %>">Initial Amount (₱)</label>
                <asp:TextBox ID="TextBox_ModalAmount" runat="server" CssClass="form-control" TextMode="Number" step="0.01" min="0" placeholder="e.g., 25.00" oninput="syncModalDurationFromAmount()"></asp:TextBox>
            </div>
        </div>
        <div class="bnet-modal-footer" style="display: flex; justify-content: flex-end; align-items: center;">
            <div style="display: flex; gap: 8px;">
                <span class="btn btn-secondary" onclick="closeRemoteEditTimeModal()">Cancel</span>
                <asp:LinkButton ID="LinkButton_SaveInitial" OnClientClick="disableRemoteEditTimeButton()" OnClick="LinkButton_SaveInitial_Click" CssClass="btn btn-primary" runat="server">Save Changes</asp:LinkButton>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    let remoteEditTimeModalInstance = null;

    function getRemoteEditTimeModal() {
        if (!remoteEditTimeModalInstance) {
            remoteEditTimeModalInstance = new BNetModal('#remoteEditTimeModal');
        }
        return remoteEditTimeModalInstance;
    }

    function openRemoteEditTimeModal(rentalId, currentDuration, currentAmount) {
        document.getElementById('<%= HiddenField_ModalRentalId.ClientID %>').value = rentalId;
        document.getElementById('<%= TextBox_ModalDuration.ClientID %>').value = currentDuration || 0;
        document.getElementById('<%= TextBox_ModalAmount.ClientID %>').value = currentAmount || '0.00';
        getRemoteEditTimeModal().open();
    }

    function closeRemoteEditTimeModal() {
        getRemoteEditTimeModal().close();
    }

    // Automatically calculate amount when duration is typed inside the modal
    function syncModalAmountFromDuration() {
        var durationBox = document.getElementById('<%= TextBox_ModalDuration.ClientID %>');
        var amountBox = document.getElementById('<%= TextBox_ModalAmount.ClientID %>');
        var minutes = parseInt(durationBox.value, 10) || 0;

        if (minutes <= 0) {
            amountBox.value = '0.00';
            return;
        }

        var customerType = (typeof getCustomerType === 'function') ? getCustomerType() : 'GUEST';
        var endpoint = /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateAmountFromDurationHandler.ashx');

        fetch(endpoint + '?minutes=' + minutes + '&customerType=' + encodeURIComponent(customerType))
            .then(function (response) { return response.json(); })
            .then(function (data) {
                if (data && data.totalAmount !== undefined) {
                    amountBox.value = data.totalAmount.toFixed(2);
                }
            })
            .catch(function (err) { console.error('Error syncing amount:', err); });
    }

    // Automatically calculate duration when amount is typed inside the modal
    function syncModalDurationFromAmount() {
        var durationBox = document.getElementById('<%= TextBox_ModalDuration.ClientID %>');
        var amountBox = document.getElementById('<%= TextBox_ModalAmount.ClientID %>');
        var amount = parseFloat(amountBox.value) || 0;

        if (amount <= 0) {
            durationBox.value = '0';
            return;
        }

        var customerType = (typeof getCustomerType === 'function') ? getCustomerType() : 'GUEST';
        var endpoint = /\.aspx$/i.test(window.location.pathname)
            ? window.location.pathname.replace(/[^\/]+\.aspx$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx')
            : window.location.pathname.replace(/[^\/]+$/i, 'Ashx/CalculateDurationFromAmountHandler.ashx');

        fetch(endpoint + '?amount=' + amount + '&customerType=' + encodeURIComponent(customerType))
            .then(function (response) { return response.json(); })
            .then(function (data) {
                if (data && data.totalMinutes !== undefined) {
                    durationBox.value = data.totalMinutes;
                }
            })
            .catch(function (err) { console.error('Error syncing duration:', err); });
    }

    // Re-initialize modal reference on ASP.NET AJAX Partial PostBacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            remoteEditTimeModalInstance = new BNetModal('#remoteEditTimeModal');
        });
    }

    function disableRemoteEditTimeButton() {
        var btn = document.querySelector('[id$="LinkButton_SaveInitial"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
        }
    }
</script>