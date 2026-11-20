<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="HowToUse.ascx.cs" Inherits="BNet.Cafe.Server.Forms.HowToUse" %>
<div class="bnet-table-wrapper htu-wrapper">

    <!-- System Notice & Deployment Instructions -->
    <div style="background-color: var(--bg-light-tertiary); border-left: 4px solid #3b82f6; border-radius: 6px; padding: 14px; margin-bottom: 16px; display: flex; flex-direction: column; gap: 12px;">

        <!-- Account Credentials -->
        <div>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 6px;">
                <i class="fas fa-key" style="color: #3b82f6; font-size: 14px;"></i>
                <span style="font-weight: 600; font-size: 13px; color: var(--text-light);">Client Bypass Credentials</span>
            </div>
            <div style="display: flex; gap: 16px; font-size: 12px; font-family: monospace; color: var(--text-light-secondary);">
                <div><strong>Username:</strong> <code style="background: rgba(0,0,0,0.15); padding: 2px 6px; border-radius: 4px; color: var(--text-light);">BNetAdmin</code></div>
                <div><strong>Password:</strong> <code style="background: rgba(0,0,0,0.15); padding: 2px 6px; border-radius: 4px; color: var(--text-light);">@12345</code></div>
            </div>
        </div>

        <hr style="border: 0; border-top: 1px solid var(--border-light); margin: 2px 0;" />

        <!-- Printing Location -->
        <div>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 6px;">
                <i class="fas fa-folder-open" style="color: #10b981; font-size: 14px;"></i>
                <span style="font-weight: 600; font-size: 13px; color: var(--text-light);">Folder Printing Location</span>
            </div>
            <div style="font-size: 12px; color: var(--text-light-secondary);">
                Files sent for printing are saved on the <strong>Server side</strong> (accessed via FTP connection from the client) in: <code style="background: rgba(0,0,0,0.15); padding: 2px 6px; border-radius: 4px; color: var(--text-light); font-family: monospace;">Documents/For Printing/</code>
            </div>
        </div>

    </div>

    <div class="bnet-table-toolbar">
        <div class="htu-header-left">
            <h2 class="htu-title"><i class="fab fa-youtube htu-yt-icon"></i>How To Use — Video Tutorials</h2>
            <p class="htu-subtitle">Watch step-by-step YouTube guides for each feature in BNet Cafe.</p>
        </div>
        <div class="toolbar-filters">
            <input type="text" id="htuSearchInput" class="search-input" placeholder="Search tutorial title, YouTube link, or notes..." />
        </div>
    </div>

    <div class="bnet-table-container">
        <table class="bnet-table htu-table">
            <thead>
                <tr>
                    <th style="width: 34%;">Tutorial Topic</th>
                    <th style="width: 24%;">YouTube Tutorial</th>
                    <th style="width: 42%;">Guide Notes</th>
                </tr>
            </thead>
            <tbody id="htuTableBody"></tbody>
        </table>
    </div>

    <div class="bnet-table-pagination-container" id="htuPagination">
        <ul class="bnet-pagination">
            <li class="page-item" id="htuPrevItem">
                <button type="button" id="htuPrevBtn" class="page-link pointer" aria-label="Previous page">
                    <i class="fas fa-chevron-left"></i>Prev
                </button>
            </li>
            <li class="page-item active">
                <span id="htuCurrentIndex" class="page-link">1</span>
            </li>
            <li class="page-item" id="htuNextItem">
                <button type="button" id="htuNextBtn" class="page-link pointer" aria-label="Next page">
                    Next <i class="fas fa-chevron-right"></i>
                </button>
            </li>
        </ul>
    </div>
</div>
