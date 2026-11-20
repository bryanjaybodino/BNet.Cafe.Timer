<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Maintenance.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Maintenance" %>
<%@ Register Src="~/Forms/Modals/RemoteMaintenance.ascx" TagPrefix="uc1" TagName="RemoteMaintenance" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:LinkButton ID="LinkButton_Refresh" runat="server"></asp:LinkButton>
        <div class="bnet-table-wrapper">
            <div class="content-header" style="margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                <div>
                    <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-screwdriver-wrench" style="color: var(--primary);"></i>Client Maintenance
                    </h1>
                    <p>Put all client PCs into maintenance mode, broadcast patch updates, clean up, shut down, or wake up clients globally</p>
                </div>
            </div>

            <!-- 4-Card Summary Grid -->
            <div class="cards-grid cards-grid-compact" style="margin-bottom: 24px;">
                <div class="card card-compact">
                    <div class="card-inline-content">
                        <div class="card-icon-sm"><i class="fa-solid fa-desktop"></i></div>
                        <div class="card-details">
                            <span class="card-title-sm">Total Computers</span>
                            <span class="card-value-sm">
                                <asp:Label ID="Label_Total" runat="server" Text="0"></asp:Label></span>
                        </div>
                    </div>
                    <span class="positive-sm">100% Total</span>
                </div>
                <div class="card card-compact">
                    <div class="card-inline-content">
                        <div class="card-icon-sm"><i class="fa-solid fa-power-off"></i></div>
                        <div class="card-details">
                            <span class="card-title-sm">Offline</span>
                            <span class="card-value-sm">
                                <asp:Label ID="Label_Offline" runat="server" Text="0"></asp:Label></span>
                        </div>
                    </div>
                    <span class="bnet-badge-status gray">Offline</span>
                </div>
                <div class="card card-compact">
                    <div class="card-inline-content">
                        <div class="card-icon-sm"><i class="fa-solid fa-user-check"></i></div>
                        <div class="card-details">
                            <span class="card-title-sm">Occupied</span>
                            <span class="card-value-sm">
                                <asp:Label ID="Label_Occupied" runat="server" Text="0"></asp:Label></span>
                        </div>
                    </div>
                    <span class="bnet-badge-status red">In Use</span>
                </div>
                <div class="card card-compact">
                    <div class="card-inline-content">
                        <div class="card-icon-sm"><i class="fa-solid fa-circle-check"></i></div>
                        <div class="card-details">
                            <span class="card-title-sm">Available</span>
                            <span class="card-value-sm">
                                <asp:Label ID="Label_Available" runat="server" Text="0"></asp:Label></span>
                        </div>
                    </div>
                    <span class="bnet-badge-status green">Ready</span>
                </div>
            </div>

            <!-- Maintenance, Clean Up, Patch & Wake On LAN Controls -->
            <div class="card" style="display: flex; flex-direction: column; gap: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.04); padding: 24px;">

                <!-- Global Maintenance Command -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary); flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 4px;">Global Maintenance Command</h3>
                        <span style="font-size: 13px; color: var(--text-light-secondary);">Broadcasts the MAINTENANCE command to all registered client computers instantly.</span>
                    </div>
                    <div>
                        <span class="btn btn-danger" onclick="openMaintenanceModal('GLOBAL_MAINTENANCE', 'All Clients')">Global Maintenance</span>
                    </div>
                </div>

                <!-- Global Clean Up Command -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary); flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 4px;">Global Clean Up Command</h3>
                        <span style="font-size: 13px; color: var(--text-light-secondary);">Broadcasts the CLEAN UP command to clean up all registered client computers instantly.</span>
                    </div>
                    <div>
                        <span class="btn btn-warning" onclick="openMaintenanceModal('GLOBAL_CLEAN_UP', 'All Clients')">Global Clean Up</span>
                    </div>
                </div>

                <!-- Global Patch Command -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary); flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 4px;">Global Patch Command</h3>
                        <span style="font-size: 13px; color: var(--text-light-secondary);">Broadcasts the PATCH command to update all registered client computers instantly.</span>
                    </div>
                    <div>
                        <span class="btn btn-primary" onclick="openMaintenanceModal('GLOBAL_PATCH', 'All Clients')">Global Patch</span>
                    </div>
                </div>

                <!-- Global Shutdown Command -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary); flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 4px;">Global Shutdown Command</h3>
                        <span style="font-size: 13px; color: var(--text-light-secondary);">Broadcasts the SHUTDOWN command to power off all registered client computers.</span>
                    </div>
                    <div>
                        <span class="btn btn-danger" onclick="openMaintenanceModal('GLOBAL_SHUTDOWN', 'All Clients')">Global Shutdown</span>
                    </div>
                </div>

                <!-- Global Wake On LAN Command -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary); flex-wrap: wrap; gap: 16px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 4px;">Global Wake On LAN Command</h3>
                        <span style="font-size: 13px; color: var(--text-light-secondary);">Broadcasts Wake-on-LAN packets to turn on all registered client computers.</span>
                    </div>
                    <div>
                        <span class="btn btn-warning" onclick="openMaintenanceModal('GLOBAL_WAKE_ON_LAN', 'All Clients')">Global Wake On LAN</span>
                    </div>
                </div>
            </div>
        </div>
        <!-- Include Separated Modal Control -->
        <uc1:RemoteMaintenance runat="server" ID="RemoteMaintenanceModal" />
    </ContentTemplate>
</asp:UpdatePanel>