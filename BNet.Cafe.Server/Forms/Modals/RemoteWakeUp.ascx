<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteWakeUp.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteWakeUp" %>
<asp:HiddenField ID="HiddenField_WakeMacAddress" runat="server" />

<div id="wakeUpModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Wake-on-LAN (WoL)</h3>
            <span class="bnet-modal-close" onclick="closeWakeUpModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Send a Magic Packet to power on computer <strong id="wakeTargetName"></strong>?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">Target MAC: <span id="wakeTargetMac" style="font-family: monospace;"></span></p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeWakeUpModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmWake" OnClientClick="disableWakeButton()" OnClick="LinkButton_ConfirmWake_Click" CssClass="btn btn-primary" runat="server">
                <i class="fa-solid fa-power-off"></i> Send Wake Signal
            </asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let wakeUpModalInstance = null;

    function getWakeUpModal() {
        if (!wakeUpModalInstance) {
            wakeUpModalInstance = new BNetModal('#wakeUpModal');
        }
        return wakeUpModalInstance;
    }

    function openWakeUpModal(name, mac) {
        document.getElementById('<%= HiddenField_WakeMacAddress.ClientID %>').value = mac;
        document.getElementById('wakeTargetName').innerText = name;
        document.getElementById('wakeTargetMac').innerText = mac;

        getWakeUpModal().open();
    }

    function closeWakeUpModal() {
        getWakeUpModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            wakeUpModalInstance = new BNetModal('#wakeUpModal');
        });
    }

    function disableWakeButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmWake"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Sending Packet...';
        }
    }
</script>