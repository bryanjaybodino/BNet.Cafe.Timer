<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="KioskMode.ascx.cs" Inherits="BNet.Cafe.Server.Forms.KioskMode" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <div class="bnet-table-wrapper">
            <!-- Header -->
            <div class="content-header" style="margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                <div>
                    <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-desktop" style="color: var(--primary);"></i>Kiosk Mode Tutorial &amp; Setup Guide
                    </h1>
                    <p>Configure and launch BNet Vendo / Kiosk mode on the BNet Server or separate client terminals using <code>kiosk-mode.bat</code></p>
                </div>
            </div>

            <!-- Quick Overview Cards -->
            <div class="cards-grid cards-grid-compact" style="margin-bottom: 24px; display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; align-items: stretch;">
                <div class="card card-compact" style="display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; gap: 14px; height: 100%; box-sizing: border-box;">
                    <div class="card-inline-content" style="display: flex; align-items: center; gap: 12px; width: 100%; min-width: 0;">
                        <div class="card-icon-sm"><i class="fa-solid fa-folder-open"></i></div>
                        <div class="card-details" style="display: flex; flex-direction: column; gap: 2px; min-width: 0; flex: 1;">
                            <span class="card-title-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Target Folder</span>
                            <span class="card-value-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Kiosk</span>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; width: 100%; margin-top: auto;">
                        <span class="positive-sm">Inside BNet Server</span>
                    </div>
                </div>
                <div class="card card-compact" style="display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; gap: 14px; height: 100%; box-sizing: border-box;">
                    <div class="card-inline-content" style="display: flex; align-items: center; gap: 12px; width: 100%; min-width: 0;">
                        <div class="card-icon-sm"><i class="fa-solid fa-terminal"></i></div>
                        <div class="card-details" style="display: flex; flex-direction: column; gap: 2px; min-width: 0; flex: 1;">
                            <span class="card-title-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Launcher Script</span>
                            <span class="card-value-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">kiosk-mode.bat</span>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; width: 100%; margin-top: auto;">
                        <span class="bnet-badge-status green">Auto-Loop</span>
                    </div>
                </div>
                <div class="card card-compact" style="display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; gap: 14px; height: 100%; box-sizing: border-box;">
                    <div class="card-inline-content" style="display: flex; align-items: center; gap: 12px; width: 100%; min-width: 0;">
                        <div class="card-icon-sm"><i class="fa-solid fa-network-wired"></i></div>
                        <div class="card-details" style="display: flex; flex-direction: column; gap: 2px; min-width: 0; flex: 1;">
                            <span class="card-title-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Remote PC URL</span>
                            <span class="card-value-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Server IP</span>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; width: 100%; margin-top: auto;">
                        <span class="bnet-badge-status gray">Replace localhost</span>
                    </div>
                </div>
                <div class="card card-compact" style="display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; gap: 14px; height: 100%; box-sizing: border-box;">
                    <div class="card-inline-content" style="display: flex; align-items: center; gap: 12px; width: 100%; min-width: 0;">
                        <div class="card-icon-sm"><i class="fa-solid fa-keyboard"></i></div>
                        <div class="card-details" style="display: flex; flex-direction: column; gap: 2px; min-width: 0; flex: 1;">
                            <span class="card-title-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Exit Kiosk</span>
                            <span class="card-value-sm" style="white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">Alt + Tab</span>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; width: 100%; margin-top: auto;">
                        <span class="bnet-badge-status red">Click X Button</span>
                    </div>
                </div>
            </div>

            <!-- Step-by-Step Instructions -->
            <div class="card" style="display: flex; flex-direction: column; gap: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.04); padding: 24px;">

                <!-- Step 1: Running on the BNet Server -->
                <div style="display: flex; flex-direction: column; gap: 12px; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 6px;">1. Running Kiosk Mode Directly on the BNet Server
                        </h3>
                        <p style="font-size: 13px; color: var(--text-light-secondary); margin-bottom: 8px;">
                            Open your <strong>BNet Server</strong> folder and locate the <strong>Kiosk</strong> subfolder (which contains <code>kiosk-mode.bat</code>, <code>BNetBrowser.exe</code>, and optional helper files such as <code>kiosk-mode.ps1</code>).
                        </p>
                        <ul style="font-size: 13px; color: var(--text-light-secondary); margin: 0 0 0 18px; line-height: 1.7;">
                            <li>Run <code>kiosk-mode.bat</code> directly to launch <strong>BNet Vendo Machine</strong> in full-screen kiosk mode.</li>
                            <li>On first run (or when edge-swipe / widgets policies are missing), Windows may prompt once for <strong>Administrator</strong> permission to apply registry policies and restart Windows Explorer once.</li>
                            <li>If <code>CLOSE_APPS=1</code> is enabled, non-protected open windows and background browsers will be closed automatically before the kiosk starts.</li>
                        </ul>
                    </div>
                    <!-- Screenshot: Step 1 -->
                    <div style="border: 1px dashed var(--border-color, #cbd5e1); border-radius: 8px; padding: 16px; text-align: center; background: rgba(0,0,0,0.02);">
                        <p style="font-size: 12px; color: var(--text-light-secondary); margin-bottom: 8px;">
                            <strong>Screenshot 1:</strong> BNet Server folder showing the <code>Kiosk</code> folder and <code>kiosk-mode.bat</code>.
                        </p>
                        <asp:Image ID="Image1" ImageUrl="~/Uploads/Kiosk/Step1.jpg" runat="server" alt="BNet Server Kiosk Folder" Style="max-width: 100%; border-radius: 6px;" />
                    </div>
                </div>

                <!-- Step 2: Running on a Separate Terminal / Client PC -->
                <div style="display: flex; flex-direction: column; gap: 12px; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 6px;">2. Setting Up Kiosk Mode on a Separate Terminal / Client PC
                        </h3>
                        <p style="font-size: 13px; color: var(--text-light-secondary); margin-bottom: 8px;">
                            If you are setting up a separate terminal or client PC apart from the main server, do not copy only the <code>.bat</code> file—copy the <strong>entire Kiosk folder</strong> to the target PC (for example, to <code>C:\Kiosk</code> or a local folder) so <code>BNetBrowser.exe</code> and supporting scripts remain together.
                        </p>
                        <ul style="font-size: 13px; color: var(--text-light-secondary); margin: 0 0 0 18px; line-height: 1.7;">
                            <li>Copy the full <strong>Kiosk</strong> folder from the BNet Server to the separate terminal/PC.</li>
                            <li>Right-click <code>kiosk-mode.bat</code> and open it with <strong>Notepad</strong> (or your text editor).</li>
                            <li>Locate the <code>set "URL=..."</code> line under the <code>CONFIG</code> section and replace <code>localhost</code> (or the sample IP) with your actual <strong>BNet Server IP address</strong> and port.</li>
                            <li>Save <code>kiosk-mode.bat</code> and run it on the terminal/PC.</li>
                        </ul>
                        <pre style="margin-top: 10px; padding: 12px; border-radius: 6px; font-size: 12px; overflow-x: auto; background: rgba(15, 23, 42, 0.9); color: #f8fafc;"><code>
:: Before (using localhost):
    set "URL=http://localhost:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"

:: After (replace localhost with your BNet Server IP address):
    set "URL=http://your-server-ip:2000/BNet.Cafe.Server/BNetVendoMachine.aspx"
                         </code></pre>
                    </div>
                    <!-- Screenshot: Step 2 -->
                    <div style="border: 1px dashed var(--border-color, #cbd5e1); border-radius: 8px; padding: 16px; text-align: center; background: rgba(0,0,0,0.02);">
                        <p style="font-size: 12px; color: var(--text-light-secondary); margin-bottom: 8px;">
                            <strong>Screenshot 2:</strong> Editing the <code>URL</code> line inside <code>kiosk-mode.bat</code> to use the Server IP address.
                        </p>
                        <asp:Image ID="Image2" ImageUrl="~/Uploads/Kiosk/Step2.jpg" runat="server" alt="BNet Server Kiosk Folder" Style="max-width: 100%; border-radius: 6px;" />
                    </div>
                </div>

                <!-- Step 3: Exit Kiosk -->
                <div style="display: flex; flex-direction: column; gap: 12px; padding: 20px; border-radius: 8px; background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin-bottom: 6px;">3. Exit Kiosk
                        </h3>
                        <p style="font-size: 13px; color: var(--text-light-secondary); margin-bottom: 8px;">
                            To exit Kiosk Mode when the desktop is shown:
                       
                        </p>
                        <ul style="font-size: 13px; color: var(--text-light-secondary); margin: 0 0 0 18px; line-height: 1.7;">
                            <li>When the desktop is shown, press <strong>Alt + Tab</strong> to switch windows.</li>
                            <li>Use the mouse and click the <strong>X</strong> (close) button on the kiosk window to exit.</li>
                            <li>If you no longer want kiosk mode to run on startup, do not run it at startup—just right-click <strong>kiosk-uninstall.bat</strong> and select <strong>Run as administrator</strong>.</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>