<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="VoucherDelete.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.VoucherDelete" %>
<asp:HiddenField ID="HiddenField_DeleteId" runat="server" />

<div id="deleteVoucherModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Confirm Voucher Deletion</h3>
            <span class="bnet-modal-close" onclick="closeVoucherDeleteModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Are you sure you want to delete voucher <strong id="deleteVoucherTargetName"></strong>?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">This action cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeVoucherDeleteModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmDelete" OnClientClick="disableVoucherDeleteButton()" OnClick="LinkButton_ConfirmDelete_Click" CssClass="btn btn-danger" runat="server">Delete</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let deleteVoucherModalInstance = null;

    function getDeleteVoucherModal() {
        if (!deleteVoucherModalInstance) {
            deleteVoucherModalInstance = new BNetModal('#deleteVoucherModal');
        }
        return deleteVoucherModalInstance;
    }

    function openVoucherDeleteModal(id, code) {
        document.getElementById('<%= HiddenField_DeleteId.ClientID %>').value = id;
        document.getElementById('deleteVoucherTargetName').innerText = code;
        getDeleteVoucherModal().open();
    }

    function closeVoucherDeleteModal() {
        getDeleteVoucherModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            deleteVoucherModalInstance = new BNetModal('#deleteVoucherModal');
        });
    }

    function disableVoucherDeleteButton() {
        var btn = document.getElementById('<%= LinkButton_ConfirmDelete.ClientID %>');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Deleting...';
        }
    }
</script>