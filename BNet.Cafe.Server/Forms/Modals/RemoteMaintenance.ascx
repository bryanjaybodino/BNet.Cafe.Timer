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
            <div id="maintenanceModalDetails" style="display: none; margin-top: 10px; font-size: 13px; text-align: left;"></div>
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
        var detailsEl = document.getElementById('maintenanceModalDetails');

        // Reset details panel; only Clean Up fills it
        detailsEl.style.display = 'none';
        detailsEl.innerHTML = '';

        if (actionType === 'SERVER_PATCH') {
            titleEl.innerText = 'Confirm Server Patch';
            msgEl.innerHTML = 'Are you sure you want to run <strong>patcher.bat</strong> on <strong>' + targetName + '</strong>?';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.innerText = 'Run Server Patch';
        } else if (actionType.includes('MAINTENANCE')) {
            titleEl.innerText = 'Confirm Maintenance Mode';
            msgEl.innerHTML = 'Are you sure you want to put <strong>' + targetName + '</strong> into Maintenance mode?';
            confirmBtn.className = 'btn btn-danger';
            confirmBtn.innerText = 'Set Maintenance';
        } else if (actionType === 'GLOBAL_CLEAN_UP') {
            titleEl.innerText = 'Confirm Global Clean Up';
            msgEl.innerHTML = 'Are you sure you want to broadcast the <strong>Clean Up</strong> command to <strong>' + targetName + '</strong>?';
            confirmBtn.className = 'btn btn-warning';
            confirmBtn.innerText = 'Run Clean Up';

            detailsEl.innerHTML =
                '<p style="margin: 0 0 4px 0;"><strong>The following will be cleaned on each client PC:</strong></p>' +
                '<ul style="margin: 0 0 8px 18px; padding: 0;">' +
                '<li><strong>Running applications</strong> &ndash; all open apps are force-closed (unsaved work is lost)</li>' +
                '<li><strong>Browser data</strong> &ndash; history, cookies, saved logins and passwords, bookmarks and extensions for Chrome, Edge, Brave, Vivaldi and Firefox</li>' +
                '<li><strong>Downloads folder</strong> &ndash; all files and folders are permanently deleted</li>' +
                '</ul>' +
                '<p style="margin: 0 0 4px 0;"><strong>Not affected:</strong></p>' +
                '<ul style="margin: 0 0 0 18px; padding: 0;">' +
                '<li>BNet applications (BNet, BNet.App1, BNet.App2, ...) are not closed</li>' +
                '<li>Windows system processes and Explorer stay running</li>' +
                '</ul>';
            detailsEl.style.display = 'block';
        } else if (actionType === 'GLOBAL_PATCH') {
            titleEl.innerText = 'Confirm Global Patch Update';
            msgEl.innerHTML = 'Are you sure you want to broadcast the <strong>Patch Update</strong> command to all registered client computers?';
            confirmBtn.className = 'btn btn-primary';
            confirmBtn.innerText = 'Run Global Patch';
        } else if (actionType === 'GLOBAL_SHUTDOWN') {
            titleEl.innerText = 'Confirm Global Shutdown';
            msgEl.innerHTML = 'Are you sure you want to shut down <strong>' + targetName + '</strong>? Any unsaved work on client PCs may be lost.';
            confirmBtn.className = 'btn btn-danger';
            confirmBtn.innerText = 'Shut Down All';
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