<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="UserDelete.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.UserDelete" %>
<asp:HiddenField ID="HiddenField_DeleteId" runat="server" />

<div id="deleteUserModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Confirm Deletion</h3>
            <span class="bnet-modal-close" onclick="closeDeleteUserModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p>Are you sure you want to delete user <strong id="deleteUserTargetName"></strong>?</p>
            <p style="color: var(--text-light-secondary); font-size: 13px; margin-top: 6px;">This action cannot be undone.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeDeleteUserModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_ConfirmDelete" OnClientClick="disableDeleteUserButton()" OnClick="LinkButton_ConfirmDelete_Click" CssClass="btn btn-danger" runat="server">Delete</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let deleteUserModalInstance = null;

    function getDeleteUserModal() {
        if (!deleteUserModalInstance) {
            deleteUserModalInstance = new BNetModal('#deleteUserModal');
        }
        return deleteUserModalInstance;
    }

    function openDeleteUserModal(id, name) {
        document.getElementById('<%= HiddenField_DeleteId.ClientID %>').value = id;
        document.getElementById('deleteUserTargetName').innerText = name;
        getDeleteUserModal().open();
    }

    function closeDeleteUserModal() {
        getDeleteUserModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            deleteUserModalInstance = new BNetModal('#deleteUserModal');
        });
    }

    function disableDeleteUserButton() {
        var btn = document.querySelector('[id$="LinkButton_ConfirmDelete"]');
        if (btn) {
            btn.classList.add('disabled');
            btn.style.pointerEvents = 'none';
            btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> Deleting...';
        }
    }
</script>