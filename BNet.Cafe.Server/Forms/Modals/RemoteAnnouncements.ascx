<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RemoteAnnouncements.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.RemoteAnnouncements" %>

<div id="remoteAnnouncementsModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">Broadcast Remote Announcement</h3>
            <span class="bnet-modal-close" onclick="closeRemoteAnnouncementsModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p style="margin-bottom: 12px; color: var(--text-light-secondary);">Type an announcement message to broadcast to all currently active PCs.</p>
            <div style="display: flex; flex-direction: column; gap: 6px;">
                <label style="font-size: 11px; font-family: monospace; font-weight: 700; color: var(--text-light-secondary); text-transform: uppercase;">Announcement Message</label>
                <asp:TextBox ID="TextBox_AnnouncementContent" TextMode="MultiLine" Rows="5" CssClass="form-control" Style="width: 100%; border-radius: 8px; padding: 10px; border: 1px solid var(--border-light); background: var(--bg-light-tertiary); resize: vertical;" runat="server" Placeholder="Type announcement here..."></asp:TextBox>
            </div>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-secondary" onclick="closeRemoteAnnouncementsModal()">Cancel</span>
            <asp:LinkButton ID="LinkButton_SendAnnouncement" runat="server" CssClass="btn btn-primary" OnClick="LinkButton_SendAnnouncement_Click">Broadcast to All PCs</asp:LinkButton>
        </div>
    </div>
</div>

<script type="text/javascript">
    let remoteAnnouncementsModalInstance = null;

    function getRemoteAnnouncementsModal() {
        if (!remoteAnnouncementsModalInstance) {
            remoteAnnouncementsModalInstance = new BNetModal('#remoteAnnouncementsModal');
        }
        return remoteAnnouncementsModalInstance;
    }

    function openRemoteAnnouncementsModal() {
        document.getElementById('<%= TextBox_AnnouncementContent.ClientID %>').value = '';
        getRemoteAnnouncementsModal().open();
    }

    function closeRemoteAnnouncementsModal() {
        getRemoteAnnouncementsModal().close();
    }

    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            remoteAnnouncementsModalInstance = new BNetModal('#remoteAnnouncementsModal');
        });
    }
</script>