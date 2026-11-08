<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Config.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Config" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <!-- Hidden field to track and preserve the active tab across postbacks -->
        <asp:HiddenField ID="hfActiveTab" runat="server" Value="tab-timer" />

        <div class="bnet-table-wrapper">
            <div class="content-header" style="margin-bottom: 24px;">
                <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                    <i class="fa-solid fa-sliders" style="color: var(--primary);"></i>Client Configuration
                </h1>
                <p>Manage system behaviors, timers, and client feature switches.</p>
            </div>

            <!-- Tab Navigation Headers -->
            <div class="config-tabs">
                <button type="button" class="config-tab-btn active" onclick="switchConfigTab(event, 'tab-timer')">
                    <i class="fa-solid fa-stopwatch"></i>Timer Config
                </button>
                <button type="button" class="config-tab-btn" onclick="switchConfigTab(event, 'tab-gamemenu')">
                    <i class="fa-solid fa-gamepad"></i>Game Menu
                </button>
                <button type="button" class="config-tab-btn" onclick="switchConfigTab(event, 'tab-schedule')">
                    <i class="fa-solid fa-clock"></i>Schedule Settings
                </button>
            </div>

            <div class="card">

                <!-- ==========================================
                   TAB 1: BNET TIMER CONFIG SECTION
                   ========================================== -->
                <div id="tab-timer" class="config-tab-pane active">
                    <div style="margin-bottom: 20px;">
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-stopwatch" style="color: var(--primary);"></i>BNet Timer Config
                        </h3>
                        <p style="font-size: 12px; color: var(--text-light-secondary);">Configure core system accounts, time zones, and timer features.</p>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_AccountCreationAllowed.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Account Creation Allowed</span>
                                <span class="toggle-desc">Enable or disable client-side user account registration.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_AccountCreationAllowed" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= DropDownList_TimeZone.ClientID %>">Server/Client Time Zone <span class="required">*</span></label>
                        <asp:DropDownList ID="DropDownList_TimeZone" runat="server" CssClass="form-control bnet-select" />
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= DropDownList_TimerSizeMode.ClientID %>">Timer Size Mode</label>
                        <asp:DropDownList ID="DropDownList_TimerSizeMode" runat="server" CssClass="form-control bnet-select">
                            <asp:ListItem Value="STANDARD" Text="Standard"></asp:ListItem>
                            <asp:ListItem Value="MINI" Text="Mini"></asp:ListItem>
                            <asp:ListItem Value="TOPMOST" Text="Topmost"></asp:ListItem>
                        </asp:DropDownList>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_AutoShutDownInterval.ClientID %>">Auto Shutdown Interval (Seconds) <span class="required">*</span></label>
                        <asp:TextBox ID="TextBox_AutoShutDownInterval" oninput="NumberOnly(this);" TextMode="Number" runat="server" CssClass="form-control" placeholder="300" MaxLength="10"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_DesktopSlideShow.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Desktop Slide Show</span>
                                <span class="toggle-desc">Enable background desktop image slideshow when idle.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_DesktopSlideShow" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_ResetShutdownCountdown.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Reset Shutdown Countdown</span>
                                <span class="toggle-desc">Automatically reset timer on user interaction.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_ResetShutdownCountdown" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_SharedDataPath.ClientID %>">Shared Data Path <span class="required">*</span></label>
                        <asp:TextBox ID="TextBox_SharedDataPath" runat="server" CssClass="form-control" placeholder="Enter shared data path (Required for diskless setup)" MaxLength="500"></asp:TextBox>

                        <div style="margin-top: 6px; padding: 10px 12px; border-left: 3px solid var(--primary); border-radius: 4px; font-size: 11px; color: var(--text-light-secondary);">
                            <strong style="color: var(--text-light);">Note: This field is required if you are using a diskless setup.</strong>
                            <ol style="margin: 4px 0 0 16px; padding: 0; line-height: 1.4;">
                                <li>Create a folder on your server or shared storage drive (e.g., <code>C:\BNet.Cafe</code>).</li>
                                <li>Right-click the folder and select <strong>Properties</strong>.</li>
                                <li>Go to the <strong>Sharing</strong> tab and click <strong>Advanced Sharing...</strong></li>
                                <li>Check <strong>Share this folder</strong>, click <strong>Permissions</strong>, and ensure <strong>Full Control</strong> / Read & Write is allowed for <em>Everyone</em>.</li>
                                <li>Make sure this folder is <strong>excluded from Deep Freeze</strong> or similar disk protection software so changes and data are saved permanently.</li>
                                <li>Paste your local path or network path here <code>\\Your-Server-Name\BNet.Cafe</code>.</li>
                            </ol>
                        </div>
                    </div>
                </div>

                <!-- ==========================================
                   TAB 2: GAME MENU SECTION
                   ========================================== -->
                <div id="tab-gamemenu" class="config-tab-pane">
                    <div style="margin-bottom: 20px;">
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-gamepad" style="color: var(--primary);"></i>Game Menu
                        </h3>
                        <p style="font-size: 12px; color: var(--text-light-secondary);">Configure comshop branding and built-in game menu launcher features.</p>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_ComshopName.ClientID %>">Comshop Name</label>
                        <asp:TextBox ID="TextBox_ComshopName" runat="server" CssClass="form-control" placeholder="Enter Comshop Name" MaxLength="100"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_EnableGameMenu.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Enable Game Menu</span>
                                <span class="toggle-desc">Enable or disable the built-in game launcher menu on client terminals.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_EnableGameMenu" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= DropDownList_LayoutMode.ClientID %>">Layout Mode</label>
                        <asp:DropDownList ID="DropDownList_LayoutMode" runat="server" CssClass="form-control bnet-select">
                            <asp:ListItem Value="GRID" Text="Grid"></asp:ListItem>
                            <asp:ListItem Value="CAROUSEL" Text="Carousel"></asp:ListItem>
                            <asp:ListItem Value="ICON" Text="Icon"></asp:ListItem>
                            <asp:ListItem Value="CIRCLE" Text="Circle"></asp:ListItem>
                        </asp:DropDownList>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_EnableMinimize.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Enable Minimize</span>
                                <span class="toggle-desc">Allow client users to minimize the game menu window.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_EnableMinimize" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_EnableWindowsKey.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Enable Windows Key</span>
                                <span class="toggle-desc">Allow using the Windows key while the game menu is open.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_EnableWindowsKey" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>
                </div>

                <!-- ==========================================
                   TAB 3: SCHEDULE SETTINGS SECTION
                   ========================================== -->
                <div id="tab-schedule" class="config-tab-pane">
                    <div style="margin-bottom: 20px;">
                        <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-clock" style="color: var(--primary);"></i>Schedule Settings
                        </h3>
                        <p style="font-size: 12px; color: var(--text-light-secondary);">Configure automated shop operating hours and shutdown closing alarms.</p>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_VIPBirthdayCredits.ClientID %>">VIP Birthday Credits (Auto Credit Points for VIPs)</label>
                        <asp:TextBox ID="TextBox_VIPBirthdayCredits" oninput="NumberOnly(this);" TextMode="Number" runat="server" CssClass="form-control" placeholder="0" MaxLength="10"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_MemberBirthdayCredits.ClientID %>">Member Birthday Credits (Auto Credit Points for Members)</label>
                        <asp:TextBox ID="TextBox_MemberBirthdayCredits" oninput="NumberOnly(this);" TextMode="Number" runat="server" CssClass="form-control" placeholder="0" MaxLength="10"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= CheckBox_EnableScheduler.ClientID %>" class="toggle-label">
                            <div class="toggle-text">
                                <span class="toggle-title">Enable Scheduler</span>
                                <span class="toggle-desc">Turn on automated closing hours schedule configuration.</span>
                            </div>
                            <label class="switch">
                                <asp:CheckBox ID="CheckBox_EnableScheduler" runat="server" />
                                <span class="slider round"></span>
                            </label>
                        </label>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_OpeningTime.ClientID %>">Opening Time</label>
                        <asp:TextBox ID="TextBox_OpeningTime" runat="server" CssClass="form-control" TextMode="Time" placeholder="08:00" MaxLength="10"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_ClosingTime.ClientID %>">Closing Time</label>
                        <asp:TextBox ID="TextBox_ClosingTime" runat="server" CssClass="form-control" TextMode="Time" placeholder="22:00" MaxLength="10"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_ClosingTimeMessage.ClientID %>">Closing Time Message</label>
                        <asp:TextBox ID="TextBox_ClosingTimeMessage" TextMode="MultiLine" Rows="2" runat="server" CssClass="form-control" placeholder="Message to display when closing"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_WarningTime.ClientID %>">Warning Time (Minutes Before Closing)</label>
                        <asp:TextBox ID="TextBox_WarningTime" oninput="NumberOnly(this);" TextMode="Number" runat="server" CssClass="form-control" placeholder="15" MaxLength="5"></asp:TextBox>
                    </div>

                    <div class="form-group" style="margin-bottom: 20px;">
                        <label for="<%= TextBox_WarningTimeMessage.ClientID %>">Warning Time Message</label>
                        <asp:TextBox ID="TextBox_WarningTimeMessage" TextMode="MultiLine" Rows="2" runat="server" CssClass="form-control" placeholder="Warning message text"></asp:TextBox>
                    </div>
                </div>
                <!-- ========================================== -->

                <div class="form-grid-action" style="margin-top: 24px;">
                    <span onclick="navigateTo('BNetPage.aspx?Form=Config')" class="btn btn-secondary">Reload</span>
                    <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click" CssClass="btn btn-primary" OnClientClick="return ValidateConfig();" runat="server">
                        <i class="fa fa-save"></i> Save Configuration
                    </asp:LinkButton>
                </div>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>