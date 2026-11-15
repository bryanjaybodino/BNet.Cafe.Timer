<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DownloadApp.ascx.cs" Inherits="BNet.Cafe.Server.Forms.DownloadApp" %>

<!-- Outer Wrapper Holding Everything -->
<div class="download-page-wrapper">

    <!-- App Download UserControl Card -->
    <div class="download-card-container">

        <!-- Left Column: Information & Details -->
        <div class="download-info-section">
            <div class="download-title-group">
                <h2 class="download-title-main">Download</h2>
                <span class="download-title-sub">BNet Cafe Timer</span>
            </div>

            <p class="download-description">
                Scan the QR code below to install the app instantly on your device.
            </p>

            <ul class="download-features-list">
                <li class="feature-item">
                    <span class="check-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </span>
                    <span>Fast Installation</span>
                </li>

                <li class="feature-item">
                    <span class="check-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </span>
                    <span>Secure Download</span>
                </li>

                <li class="feature-item">
                    <span class="check-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </span>
                    <span>Works on Android and Windows Devices.</span>
                </li>

                <li class="feature-item" style="margin-top: 4px;">
                    <span class="check-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </span>
                    <span class="version-badge">Application Version</span>
                </li>
            </ul>

            <!-- SSL / PWA Edge Flag Notice -->
            <div class="ssl-instruction-box">
                <div class="ssl-instruction-title">
                    ⚠️ Installation Warning (Local IP / HTTPS)
                </div>
                If the install button shows "Not Applicable", open 
                <a href="chrome://flags/#unsafely-treat-insecure-origin-as-secure" 
                   class="ssl-flag-link" 
                   onclick="openFlagLink(event, 'chrome://flags/#unsafely-treat-insecure-origin-as-secure');">
                   chrome://flags/#unsafely-treat-insecure-origin-as-secure
                </a>, 
                set it to <b>Enabled</b>, and add <code><%= Request.Url.Scheme %>://<%= Request.Url.Authority %></code> to the allowed list.
            </div>
        </div>

        <!-- Right Column: QR Code & Download Button -->
        <div class="download-action-section">
            <!-- Floating QR Box -->
            <div class="qr-code-card">
                <asp:Image ID="imgQrCode" runat="server" CssClass="qr-code-img" AlternateText="QR Code" ImageUrl="~/Images/zion-qr-sample.png" />
                <span class="qr-caption">Scan to Download</span>
            </div>

            <!-- Download Action Button -->
            <asp:HyperLink ID="HyperLink_Url" runat="server" NavigateUrl="~/App/Installation.aspx" CssClass="btn-download-installer">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                      <polyline points="7 10 12 15 17 10"></polyline>
                      <line x1="12" y1="15" x2="12" y2="3"></line>
                  </svg>
                  <span>Download Installer</span>
            </asp:HyperLink>
        </div>

    </div>

    <!-- Modern YouTube Video Embed Card -->
    <div class="youtube-embed-card">
        <div class="youtube-header-group">
            <h3 class="youtube-title-main">Tutorial</h3>
            <span class="youtube-title-sub">Watch Installation Guide</span>
        </div>

        <div class="video-wrapper">
            <iframe 
                src="https://www.youtube.com/embed/8S-PL1pyA2g?si=1_HtztzKpBF9hYUB" 
                title="BNet Cafe Installation Video Guide" 
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
                referrerpolicy="strict-origin-when-cross-origin" 
                allowfullscreen>
            </iframe>
        </div>
    </div>
</div>