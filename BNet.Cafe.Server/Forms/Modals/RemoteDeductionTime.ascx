<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteDeductionTime.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteDeductionTime" %>

<!-- Hidden fields to preserve state inside modal -->
<asp:HiddenField ID="HiddenField_ModalRentalId" runat="server" />
<asp:HiddenField ID="HiddenField_ModalOriginalAmount" runat="server" />

<!-- BNet Modal Template -->
<div id="remoteDeductionTimeModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container" style="width: 420px;" onclick="event.stopPropagation()">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Deduct Time</h3>
            <span class="bnet-modal-close" onclick="closeRemoteDeductionTimeModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p style="margin-bottom: 16px; color: var(--text-light-secondary); font-size: 13px;">
                Enter the number of minutes to deduct from the customer's session. The total amount will remain unchanged.
            </p>

            <div class="form-group" style="margin-bottom: 12px;">
                <label for="<%= TextBox_ModalDeductMinutes.ClientID %>">Minutes to Deduct</label>
                <asp:TextBox ID="TextBox_ModalDeductMinutes" runat="server" CssClass="form-control" TextMode="Number" min="0" placeholder="e.g., 30" oninput="NumberOnly(this); calculateDeductedDuration()"></asp:TextBox>
            </div>

            <div class="form-group" style="margin-bottom: 12px;">
                <label for="<%= TextBox_ModalNewDuration.ClientID %>">New Resulting Duration (Minutes)</label>
                <!-- Removed ReadOnly="true" and added onkeydown="return false;" so the value successfully posts back -->
                <asp:TextBox ID="TextBox_ModalNewDuration" runat="server" CssClass="form-control" TextMode="Number" min="0" placeholder="Calculated duration" onkeydown="return false;" style="background-color: var(--form-control-disabled-bg, #f5f5f5); opacity: 1; cursor: not-allowed;"></asp:TextBox>
            </div>

            <div class="form-group" style="margin-bottom: 8px;">
                <label for="<%= TextBox_ModalAmount.ClientID %>">Amount (₱) - Unchanged</label>
                <asp:TextBox ID="TextBox_ModalAmount" runat="server" CssClass="form-control" TextMode="Number" step="0.01" onkeydown="return false;" style="background-color: var(--form-control-disabled-bg, #f5f5f5); opacity: 1; cursor: not-allowed;"></asp:TextBox>
            </div>
        </div>
        <div class="bnet-modal-footer" style="display: flex; justify-content: flex-end; align-items: center;">
            <div style="display: flex; gap: 8px;">
                <span class="btn btn-secondary" onclick="closeRemoteDeductionTimeModal()">Cancel</span>
                <asp:LinkButton ID="LinkButton_SaveDeduction" OnClientClick="disableRemoteDeductionTimeButton()" OnClick="LinkButton_SaveDeduction_Click" CssClass="btn btn-primary" runat="server">Confirm Deduction</asp:LinkButton>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    let remoteDeductionTimeModalInstance = null;
    let originalCurrentDuration = 0;

    function getRemoteDeductionTimeModal() {
        if (!remoteDeductionTimeModalInstance) {
            remoteDeductionTimeModalInstance = new BNetModal('#remoteDeductionTimeModal');
        }
        return remoteDeductionTimeModalInstance;
    }

    function openRemoteDeductionTimeModal(rentalId, currentDuration, currentAmount) {
        originalCurrentDuration = parseInt(currentDuration, 10) || 0;

        document.getElementById('<%= HiddenField_ModalRentalId.ClientID %>').value = rentalId;
        document.getElementById('<%= HiddenField_ModalOriginalAmount.ClientID %>').value = currentAmount || '0.00';
        
        document.getElementById('<%= TextBox_ModalDeductMinutes.ClientID %>').value = '';
        document.getElementById('<%= TextBox_ModalNewDuration.ClientID %>').value = originalCurrentDuration;
        document.getElementById('<%= TextBox_ModalAmount.ClientID %>').value = currentAmount || '0.00';

        getRemoteDeductionTimeModal().open();
    }

    function closeRemoteDeductionTimeModal() {
        getRemoteDeductionTimeModal().close();
    }

    // Automatically recalculate remaining duration when minutes to deduct are typed
    function calculateDeductedDuration() {
        var deductBox = document.getElementById('<%= TextBox_ModalDeductMinutes.ClientID %>');
        var newDurationBox = document.getElementById('<%= TextBox_ModalNewDuration.ClientID %>');

        var minutesToDeduct = parseInt(deductBox.value, 10) || 0;
        var calculatedDuration = originalCurrentDuration - minutesToDeduct;

        // Prevent negative duration values
        if (calculatedDuration < 0) {
            calculatedDuration = 0;
        }

        if (newDurationBox) {
            newDurationBox.value = calculatedDuration;
        }
    }

    // Re-initialize modal reference on ASP.NET AJAX Partial PostBacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            remoteDeductionTimeModalInstance = new BNetModal('#remoteDeductionTimeModal');
        });
    }

    function disableRemoteDeductionTimeButton() {
        var btn = document.querySelector('[id$="LinkButton_SaveDeduction"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Saving...';
        }
    }
</script>