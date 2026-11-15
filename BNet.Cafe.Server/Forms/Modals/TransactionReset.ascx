<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TransactionReset.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.TransactionReset" %>
<asp:HiddenField ID="HiddenField_ResetToken" runat="server" />

<div id="resetTransactionModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Confirm Collection Reset</h3>
            <span class="bnet-modal-close" onclick="closeResetModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Are you sure you want to reset all current collections for this period?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">This action will archive current collections and cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeResetModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmReset" OnClientClick="disableResetButton()" OnClick="LinkButton_ConfirmReset_Click" CssClass="btn btn-danger" runat="server">Reset Collection</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let resetTransactionModalInstance = null;

    function getResetTransactionModal() {
        if (!resetTransactionModalInstance) {
            resetTransactionModalInstance = new BNetModal('#resetTransactionModal');
        }
        return resetTransactionModalInstance;
    }

    function openResetModal() {
        getResetTransactionModal().open();
    }

    function closeResetModal() {
        getResetTransactionModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            resetTransactionModalInstance = new BNetModal('#resetTransactionModal');
        });
    }

    function disableResetButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmReset"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Resetting...';
        }
    }
</script>