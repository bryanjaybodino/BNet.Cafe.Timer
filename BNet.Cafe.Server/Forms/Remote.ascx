<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Remote.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Remote" %>
<%@ Register Src="~/Forms/Modals/RemoteMessage.ascx" TagPrefix="uc" TagName="RemoteMessage" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <!-- Remote Message Modal -->
        <uc:RemoteMessage ID="RemoteMessageModal" runat="server" />
    </ContentTemplate>
</asp:UpdatePanel>


<div class="computers-app" id="app">
    <main class="main">
        <div class="device-list" id="deviceList">
            <div id="noDevices" style="grid-column: 1 / -1; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 50px 20px; color: var(--text-light-secondary); text-align: center;">
                <svg style="width: 36px; height: 36px; margin-bottom: 10px; opacity: 0.4; fill: currentColor;" viewBox="0 0 24 24">
                    <path d="M21 2H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h7v2H8v2h8v-2h-2v-2h7c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H3V4h18v12z" />
                </svg>
                <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">Waiting for connected PCs…</div>
                <div style="font-size: 12px; opacity: 0.7;">Client stations will appear here once they connect to the network.</div>
            </div>
        </div>
    </main>

    <aside class="details-sidebar" id="detailsSidebar">
        <br />
        <div class="info-panel" id="infoPanel">
            <div class="sec-label">Station Hardware & System</div>
            <div class="info-scroll">
                <div class="info-row">
                    <div class="info-key">Account Name</div>
                    <div class="info-val" id="Username">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Machine Name</div>
                    <div class="info-val" id="MachineName">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Workgroup</div>
                    <div class="info-val" id="Workgroup">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Windows</div>
                    <div class="info-val" id="Windows">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Windows Version</div>
                    <div class="info-val" id="WindowsVersion">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">OS Version</div>
                    <div class="info-val" id="OSVersion">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Architecture</div>
                    <div class="info-val" id="OSArchitecture">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Serial Number</div>
                    <div class="info-val" id="SerialNumber">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Processor Count</div>
                    <div class="info-val" id="ProcessorCount">—</div>
                </div>
                <div class="info-row">
                    <div class="info-key">Screen Count</div>
                    <div class="info-val" id="ScreenCount">—</div>
                </div>
            </div>
            <!-- Action Buttons Layout -->
            <div class="sidebar-actions">
                <a class="remote-launch-btn" id="remoteLaunchBtn" href="#">🖥 Launch Full Screen View</a>
                <button type="button" class="btn-sidebar-action" id="remoteMsgBtn" onclick="openRemoteMessageModal(currentClient)">💬 Message Client</button>
            </div>
        </div>
        <div class="sidebar-foot">⬡ &nbsp;<span id="clock">--:--:--</span></div>
    </aside>
</div>
