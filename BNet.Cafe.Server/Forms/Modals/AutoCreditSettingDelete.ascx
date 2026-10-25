<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AutoCreditSettingDelete.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.AutoCreditSettingDelete" %>
<asp:HiddenField ID="HiddenField_DeleteAutoCreditId" runat="server" />

<div id="deleteAutoCreditModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Confirm Deletion</h3>
            <span class="bnet-modal-close" onclick="closeAutoCreditDeleteModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Are you sure you want to delete this auto credit rate</p>
            <p>(<strong id="deleteAutoCreditTargetInfo"></strong>)?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">This action cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeAutoCreditDeleteModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmDelete" OnClientClick="disableAutoCreditDeleteButton()" OnClick="LinkButton_ConfirmDelete_Click" CssClass="btn btn-danger" runat="server">Delete</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let deleteAutoCreditModalInstance = null;

    function getDeleteAutoCreditModal() {
        if (!deleteAutoCreditModalInstance) {
            deleteAutoCreditModalInstance = new BNetModal('#deleteAutoCreditModal');
        }
        return deleteAutoCreditModalInstance;
    }

    function openAutoCreditDeleteModal(id, info) {
        document.getElementById('<%= HiddenField_DeleteAutoCreditId.ClientID %>').value = id;
        document.getElementById('deleteAutoCreditTargetInfo').innerText = info;

        getDeleteAutoCreditModal().open();
    }

    function closeAutoCreditDeleteModal() {
        getDeleteAutoCreditModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            deleteAutoCreditModalInstance = new BNetModal('#deleteAutoCreditModal');
        });
    }

    function disableAutoCreditDeleteButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmDelete"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Deleting...';
        }
    }
</script>