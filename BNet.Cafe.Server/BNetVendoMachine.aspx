<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="BNetVendoMachine.aspx.cs" Inherits="BNet.Cafe.Server.BNetVendoMachine" %>

<!DOCTYPE html>
<html lang="en">
<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, interactive-widget=resizes-none">
    <title>BNet Cafe Vendo Machine</title>
    <link href="Assets/fontawesome/font-awesome.min.css" rel="stylesheet" />
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/Vendo/Style.css")); %>
</head>
<body oncontextmenu="return false;">
    <div class="slider-container" id="slider">
        <div class="loading" id="loadingText">Scanning wallpapers...</div>
    </div>

    <div class="vignette-overlay"></div>

    <div class="psp-container" style="display: none" id="pspContainer">
        <div class="psp-carousel" id="pspCarousel"></div>
    </div>

    <!-- Independent Idle Countdown Footer (Visible when pspContainer is unlocked) -->
    <div class="attract-footer" id="idleCountdownFooter" style="display: none; position: fixed; bottom: 10px; left: 0; width: 100%; z-index: 99; pointer-events: none;">
        <div class="attract-banner" id="attractBanner">
            <i class="fas fa-lock" id="bannerIcon"></i>
            <span id="bannerText">LOCKING IN 10s</span>
        </div>
    </div>

    <!-- Press Any Key Overlay Screen: full screen cover when locked -->
    <div id="pressAnyKeyScreen">
        <div class="attract-header">
            <span class="attract-brand">BNet Cafe</span>
        </div>
        <div class="attract-grid" id="attractGrid"></div>
        <div class="attract-footer">
            <div class="attract-banner"><i class="fas fa-hand-pointer"></i><span>PRESS ANY KEY</span></div>
        </div>
    </div>

    <!-- Number Input Popup Modal -->
    <div class="number-modal-overlay" id="numberModal">
        <div class="number-modal-box">
            <div class="number-modal-pc-target" id="modalPcTarget">PC-01</div>
            <div class="number-modal-label">Inserted Coins</div>
            <div class="number-modal-display" id="modalNumberDisplay">0</div>
            <div class="number-modal-timer" id="modalTimerText">Closing in 5s</div>
        </div>
    </div>
    <form runat="server" id="MainForm">
        <asp:ScriptManager ID="ScriptManager1" EnableCdn="false" EnablePageMethods="true" EnablePartialRendering="true" AsyncPostBackTimeout="99999999" ScriptMode="Release" ValidateRequestMode="Enabled" EnableScriptLocalization="true" EnableScriptGlobalization="true" LoadScriptsBeforeUI="false" CompositeScript-ScriptMode="Release" CompositeScript-ResourceUICultures="Release" runat="server"></asp:ScriptManager>
        <asp:UpdatePanel ID="UpdatePanelModalTrigger" runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <asp:LinkButton ID="LinkButton_ProcessVendo" runat="server"
                    OnClick="LinkButton_ProcessVendo_Click" Style="display: none;" />
                <asp:HiddenField ID="HiddenField_ModalAmount" runat="server" />
                <asp:HiddenField ID="HiddenField_ModalComputerName" runat="server" />



                <!-- License Modal -->
                <asp:Panel ID="licenseModal" runat="server" CssClass="number-modal-overlay visible" ClientIDMode="Static">
                    <div class="number-modal-box" style="max-width: 420px;">
                        <div class="number-modal-pc-target">Server Licensing</div>
                        <div class="number-modal-label" style="margin-top: 10px;">Unique Server Serial Number</div>
                        <asp:TextBox ID="TextBox_ServerSerial" runat="server" ReadOnly="true" class="license-input" Style="font-family: monospace; font-size: 1.1rem; margin: 10px 0; text-align: center" value=""></asp:TextBox>
                        <div class="number-modal-label">Enter License Key</div>
                        <asp:TextBox ID="TextBox_LicenseKey" runat="server" CssClass="license-input" Style="text-align: center" placeholder="Paste license..." /><br />
                        <asp:LinkButton ID="LinkButton_ActivateLicense" runat="server" CssClass="btn-activate" OnClick="LinkButton_ActivateLicense_Click">Activate License</asp:LinkButton>
                        <asp:Label ID="Label_LicenseMessage" runat="server" Style="display: block; margin-top: 10px; font-size: 0.85rem;" />
                    </div>
                </asp:Panel>
            </ContentTemplate>
        </asp:UpdatePanel>
    </form>
</body>
</html>
