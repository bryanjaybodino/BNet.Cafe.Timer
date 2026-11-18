<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteMaintenance.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteMaintenance" %>

<asp:HiddenField ID="HiddenField_MaintenanceAction" runat="server" />
<asp:HiddenField ID="HiddenField_MaintenanceClientId" runat="server" />

<!-- BNet Modal Template -->
<div id="maintenanceModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title" id="maintenanceModalTitle">Confirm Action</h3>
            <span class="bnet-modal-close" onclick="closeMaintenanceModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p id="maintenanceModalMessage">Are you sure you want to perform this action?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">This action cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeMaintenanceModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmMaintenance" OnClientClick="disableMaintenanceButton()" OnClick="LinkButton_ConfirmMaintenance_Click" CssClass="btn btn-danger" runat="server">Confirm</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let maintenanceModalInstance = null;

    function getMaintenanceModal() {
        if (!maintenanceModalInstance) {
            maintenanceModalInstance = new BNetModal('#maintenanceModal');
        }
        return maintenanceModalInstance;
    }

    function openMaintenanceModal(actionType, targetName) {
        document.getElementById('<%= HiddenField_MaintenanceAction.ClientID %>').value = actionType;
        document.getElementById('<%= HiddenField_MaintenanceClientId.ClientID %>').value = targetName;

        var titleEl = document.getElementById('maintenanceModalTitle');
        var msgEl = document.getElementById('maintenanceModalMessage');
        var confirmBtn = document.querySelector('[id$="LinkButton_ConfirmMaintenance"]');

        if (actionType.includes('MAINTENANCE')) {
            titleEl.innerText = 'Confirm Maintenance Mode';
            msgEl.innerHTML = 'Are you sure you want to put <strong>' + targetName + '</strong> into Maintenance mode?';
            confirmBtn.className = 'btn btn-danger';
            confirmBtn.innerText = 'Set Maintenance';
        } else {
            titleEl.innerText = 'Confirm Wake On LAN';
            msgEl.innerHTML = 'Are you sure you want to broadcast Wake On LAN packets to <strong>' + targetName + '</strong>?';
            confirmBtn.className = 'btn btn-warning';
            confirmBtn.innerText = 'Send Wake On LAN';
        }

        getMaintenanceModal().open();
    }

    function closeMaintenanceModal() {
        getMaintenanceModal().close();
    }

    // Re-initialize modal reference on ASP.NET AJAX Partial PostBacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            maintenanceModalInstance = new BNetModal('#maintenanceModal');
        });
    }

    function disableMaintenanceButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmMaintenance"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Processing...';
        }
    }
</script>