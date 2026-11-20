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
        <!-- Toolbar: count, search, sort -->
        <div class="toolbar">
            <div class="toolbar-title">
                <h2>Stations</h2>
                <span class="count-pill" id="deviceCount">0 online</span>
            </div>
            <div class="toolbar-tools">
                <label class="search-box">
                    <svg viewBox="0 0 24 24"><path d="M15.5 14h-.79l-.28-.27A6.47 6.47 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z" /></svg>
                    <input type="search" class="search-input" id="deviceSearch" placeholder="Search PC…" autocomplete="off" />
                </label>
                <button type="button" class="sort-btn" id="sortBtn" title="Toggle sort order">
                    <svg viewBox="0 0 24 24"><path d="M3 18h6v-2H3v2zM3 6v2h18V6H3zm0 7h12v-2H3v2z" /></svg>
                    <span id="sortLabel">A → Z</span>
                </button>
            </div>
        </div>

        <div class="device-list" id="deviceList">
            <div class="no-devices" id="noDevices">
                <svg style="width: 36px; height: 36px; margin-bottom: 10px; opacity: 0.4; fill: currentColor;" viewBox="0 0 24 24">
                    <path d="M21 2H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h7v2H8v2h8v-2h-2v-2h7c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H3V4h18v12z" />
                </svg>
                <div style="font-weight: 600; font-size: 14px; margin-bottom: 4px;">Waiting for connected PCs…</div>
                <div style="font-size: 12px; opacity: 0.7;">Client stations will appear here once they connect to the network.</div>
            </div>
        </div>
    </main>

    <div class="sidebar-backdrop" id="sidebarBackdrop"></div>

    <aside class="details-sidebar" id="detailsSidebar">
        <div class="sidebar-head">
            <div class="sec-label">Station Hardware &amp; System</div>
            <button type="button" class="sidebar-close" id="sidebarClose" aria-label="Close" onclick="deselectDevice()">&#10005;</button>
        </div>
        <div class="info-panel" id="infoPanel">
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
