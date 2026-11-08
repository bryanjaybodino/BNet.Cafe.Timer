<%@ Page Language="C#" AutoEventWireup="true" Async="true" EnableEventValidation="false" AsyncTimeout="1000000000" CodeBehind="Portal.aspx.cs" Inherits="BNet.Cafe.Server.Portal" %>

<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <script>
        (function () {
            var savedTheme = localStorage.getItem('theme') || 'light';
            document.documentElement.setAttribute('data-theme', savedTheme);
            document.documentElement.classList.add('no-transitions');
        })();
    </script>
    <meta charset="UTF-8" />
    <meta name='viewport' content='width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no' />
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <meta name="google" content="notranslate" />
    <meta name="robots" content="noarchive, noindex, nosnippet" />
    <link rel="icon" type="image/png" href="App/icon.png">
    <title>BNet Cafe - Portal</title>
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/Portal/Style.css")); %>
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/BNetSelect/Style.css")); %>
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/Pages/Style.css")); %>
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/BNetTable/Style.css")); %>
    <% Response.Write(BNet.Cafe.Server.Services.FileCssHelper.StyleSheetVersion("Assets/fontawesome/font-awesome.min.css")); %>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" EnableCdn="false" EnablePageMethods="true" EnablePartialRendering="true" AsyncPostBackTimeout="99999999" ScriptMode="Release" ValidateRequestMode="Enabled" EnableScriptLocalization="true" EnableScriptGlobalization="true" LoadScriptsBeforeUI="false" CompositeScript-ScriptMode="Release" CompositeScript-ResourceUICultures="Release" runat="server"></asp:ScriptManager>
        <div class="portal-layout">


            <!-- Main Content Area -->
            <main>
                <!-- Combined User Profile & Actions Hero Card -->
                <div class="user-hero-card">
                    <div class="hero-avatar">
                        <asp:Literal ID="litAvatar" runat="server">U</asp:Literal>
                    </div>
                    <div class="hero-details">
                        <div class="hero-name">
                            <asp:Literal ID="litUserName" runat="server"></asp:Literal>
                        </div>
                        <div class="hero-email">
                            <asp:Literal ID="litUserEmail" runat="server"></asp:Literal>
                        </div>
                        <div class="hero-badge">
                            <i class="fa fa-circle"></i>Active Account
                       
                        </div>
                    </div>
                    <!-- Integrated Actions inside the Hero Card -->
                    <div class="hero-actions">
                        <button type="button" class="btn-theme-toggle" id="themeToggle" title="Toggle theme">
                            <i class="fa fa-moon"></i>
                        </button>
                        <asp:Button ID="btnLogout" runat="server" Text="Logout" CssClass="btn-logout-modern" OnClick="btnLogout_Click" />
                    </div>
                </div>

                <!-- Grid Container for Dual Balance Cards -->
                <div class="balance-cards-grid">
                    <!-- Card 1: Active Session Balance -->
                    <div class="balance-card session-card">
                        <div class="card-label">
                            <i class="fa fa-play-circle"></i>Active Session Time
                        </div>
                        <div class="balance-value">
                            <asp:Literal ID="litActiveSessionTime" runat="server">0 mins</asp:Literal>
                        </div>
                        <div class="balance-footer">
                            Deducted for current session: <span>
                                <asp:Literal ID="litActiveSessionMins" runat="server">0</asp:Literal>
                                mins</span>
                        </div>
                    </div>

                    <!-- Card 2: Account / Top-Up Balance -->
                    <div class="balance-card account-card">
                        <div class="card-label">
                            <i class="fa fa-wallet"></i>Account Balance (Top-Ups)
                        </div>
                        <div class="balance-value">
                            <asp:Literal ID="litAccountBalanceTime" runat="server">0 mins</asp:Literal>
                        </div>
                        <div class="balance-footer">
                            Available to claim: <span>
                                <asp:Literal ID="litAccountBalanceMins" runat="server">0</asp:Literal>
                                mins</span>
                        </div>
                    </div>

                    <!-- Card 3: Total Points -->
                    <div class="balance-card points-card">
                        <div class="card-label">
                            <i class="fa fa-star"></i>Total Points
                        </div>
                        <div class="balance-value">
                            <asp:Literal ID="litTotalPoints" runat="server">0</asp:Literal>
                        </div>
                        <div class="balance-footer">
                            Accumulated reward points
                        </div>
                    </div>
                </div>

                <asp:UpdatePanel ID="UpdatePanel1" runat="server">
                    <ContentTemplate>
                        <asp:HiddenField ID="HiddenField_UserId" runat="server" />
                        <asp:HiddenField ID="HiddenField_CustomerType" runat="server" />
                        <asp:HiddenField ID="HF_RedeemMinutes" runat="server" />
                        <asp:HiddenField ID="HF_RedeemPoints" runat="server" />
                        <!-- Tabs Navigation using LinkButton -->
                        <div class="portal-tabs">
                            <asp:LinkButton ID="lnkTabTransactions" runat="server" CssClass="portal-tab active" OnClick="lnkTab_Click" CommandArgument="Transactions">
                                <i class="fa fa-history"></i> Transactions
                            </asp:LinkButton>
                            <asp:LinkButton ID="lnkTabPointsHistory" runat="server" CssClass="portal-tab" OnClick="lnkTab_Click" CommandArgument="PointsHistory">
                                <i class="fa fa-star"></i> Points History
                            </asp:LinkButton>
                            <asp:LinkButton ID="lnkTabRedeem" runat="server" CssClass="portal-tab" OnClick="lnkTab_Click" CommandArgument="Redeem">
                                <i class="fa fa-gift"></i> Redeem Rewards
                            </asp:LinkButton>
                            <asp:LinkButton ID="lnkTabTransfer" runat="server" CssClass="portal-tab" OnClick="lnkTab_Click" CommandArgument="Transfer">
                                <i class="fa fa-exchange-alt"></i> Transfer Balance
                            </asp:LinkButton>
                        </div>

                        <!-- Tab 1: Transaction History Panel -->
                        <asp:Panel ID="PanelTransactions" runat="server" CssClass="tab-content-panel">
                            <div class="bnet-table-wrapper">
                                <div class="bnet-table-toolbar">
                                    <div style="font-size: 16px; font-weight: 700; color: var(--portal-text-main); display: flex; align-items: center; gap: 8px;">
                                        <i class="fa fa-history"></i>Transaction History
                                    </div>
                                </div>
                                <div class="bnet-table-container">
                                    <asp:GridView ID="GridViewTable" runat="server" ShowHeaderWhenEmpty="true"
                                        AutoGenerateColumns="False" CssClass="bnet-table" GridLines="None"
                                        AllowPaging="True" OnPageIndexChanging="GridViewTable_PageIndexChanging">
                                        <Columns>
                                            <asp:TemplateField HeaderText="#">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBId" runat="server" Text='<%# Eval("DBId") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Date">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBDateCreated" runat="server" Text='<%# Eval("DBDateCreated") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Time">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBTimeCreated" runat="server" Text='<%# Eval("DBTimeCreated") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Minutes">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBDuration" runat="server" Text='<%# Eval("DBDuration") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Duration">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBFormattedDuration" runat="server" Text='<%# Eval("DBFormattedDuration") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Amount">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBAmount" runat="server" Text='<%# Eval("DBAmount") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Description">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_DBDescription" runat="server" Text='<%# Eval("DBDescription") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                        </Columns>
                                    </asp:GridView>
                                    <asp:Panel ID="Panel_Pagination" runat="server" CssClass="bnet-table-pagination-container" />
                                </div>
                            </div>
                        </asp:Panel>

                        <!-- Tab 2: Points History Panel -->
                        <asp:Panel ID="PanelPointsHistory" runat="server" CssClass="tab-content-panel" Visible="false">
                            <div class="bnet-table-wrapper">
                                <div class="bnet-table-toolbar">
                                    <div style="font-size: 16px; font-weight: 700; color: var(--portal-text-main); display: flex; align-items: center; gap: 8px;">
                                        <i class="fa fa-star"></i>Points History
                                    </div>
                                </div>
                                <div class="bnet-table-container">
                                    <asp:GridView ID="GridViewPoints" runat="server" ShowHeaderWhenEmpty="true"
                                        AutoGenerateColumns="False" CssClass="bnet-table" GridLines="None"
                                        AllowPaging="True" OnPageIndexChanging="GridViewPoints_PageIndexChanging">
                                        <Columns>
                                            <asp:TemplateField HeaderText="Date">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_PointsDate" runat="server" Text='<%# Eval("DBDateCreated") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Time">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_PointsTime" runat="server" Text='<%# Eval("DBTimeCreated") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Points">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_PointsValue" runat="server" Text='<%# Eval("DBPoints") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                            <asp:TemplateField HeaderText="Description">
                                                <ItemTemplate>
                                                    <asp:Label ID="Label_PointsDescription" runat="server" Text='<%# Eval("DBDescription") %>'></asp:Label>
                                                </ItemTemplate>
                                            </asp:TemplateField>
                                        </Columns>
                                    </asp:GridView>
                                    <asp:Panel ID="Panel_PointsPagination" runat="server" CssClass="bnet-table-pagination-container" />
                                </div>
                            </div>
                        </asp:Panel>

                        <!-- Tab 3: Redeem Points Panel -->
                        <asp:Panel ID="PanelRedeem" runat="server" CssClass="tab-content-panel" Visible="false">
                            <div class="user-hero-card" style="flex-direction: column; align-items: flex-start; gap: 12px; margin-bottom: 20px;">
                                <div style="font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 8px; color: var(--portal-text-main);">
                                    <i class="fa fa-tags" style="color: var(--portal-accent);"></i>Available Pricing Rates (<asp:Literal ID="litCustomerType" runat="server">MEMBER</asp:Literal>)
                                </div>
                                <div style="font-size: 13px; color: var(--portal-text-muted);">
                                    Redeem your accumulated reward points for time based on your active pricing tier.
                                </div>
                                <asp:Repeater ID="RepeaterPricingRates" runat="server" OnItemCommand="RepeaterPricingRates_ItemCommand">
                                    <HeaderTemplate>
                                        <div class="pricing-rates-grid" style="width: 100%;">
                                    </HeaderTemplate>
                                    <ItemTemplate>
                                        <div class="pricing-rate-card">
                                            <div class="pricing-rate-minutes"><%# Eval("DBMinutes") %> Mins</div>
                                            <div class="pricing-rate-price">₱<%# Eval("DBPrice") %></div>
                                            <div style="font-size: 11px; color: var(--portal-text-muted); margin-bottom: 12px;">
                                                Cost: <%# Eval("DBPrice") %> Points
                                            </div>
                                            <asp:Button ID="btnRedeemRate" runat="server" CssClass="btn-redeem-rate" Text="Redeem"
                                                CommandName="PrepareRedeem" CommandArgument='<%# Eval("DBMinutes") + "|" + Eval("DBPrice") %>' />
                                        </div>
                                    </ItemTemplate>
                                    <FooterTemplate>
                                        </div>
                                    </FooterTemplate>
                                </asp:Repeater>
                            </div>
                        </asp:Panel>

                        <!-- Tab 4: Transfer Balance Panel -->
                        <asp:Panel ID="PanelTransfer" runat="server" CssClass="tab-content-panel" Visible="false">
                            <div class="user-hero-card" style="flex-direction: column; align-items: flex-start; gap: 16px; margin-bottom: 20px;">
                                <div style="width: 100%; display: flex; justify-content: space-between; align-items: center;">
                                    <div style="font-size: 16px; font-weight: 700; display: flex; align-items: center; gap: 8px; color: var(--portal-text-main);">
                                        <i class="fa fa-exchange-alt" style="color: var(--portal-accent);"></i>Transfer Time Balance to Another User
                                    </div>
                                    <!-- Hidden or subtle PC Number label safely contained without layout impact -->
                                    <asp:Label ID="Label_PCNumber" runat="server" Text="" Style="display: none;"></asp:Label>
                                </div>
                                <div style="font-size: 13px; color: var(--portal-text-muted);">
                                    Send available account balance minutes safely to another registered user.                              
                                </div>
                                <!-- Transfer Warning Note -->
                                <div style="font-size: 12px; color: #f59e0b; background: rgba(245, 158, 11, 0.1); padding: 8px 12px; border-radius: 8px; border: 1px solid rgba(245, 158, 11, 0.2); display: flex; align-items: center; gap: 8px; width: 100%;">
                                    <i class="fa fa-exclamation-triangle"></i>
                                    <span><strong>Note:</strong> Completing a successful balance transfer will automatically force-logout your account for session security.</span>
                                </div>

                                <div style="width: 100%; display: flex; flex-direction: column; gap: 14px; max-width: 480px;">
                                    <!-- Customer Selection Dropdown -->
                                    <div class="form-group" style="display: flex; flex-direction: column; gap: 6px;">
                                        <label for="<%= DropDownList_Customer.ClientID %>" style="font-size: 13px; font-weight: 700; color: var(--portal-text-main);">
                                            Recipient Customer <span style="color: #ef4444;">*</span>
                                        </label>
                                        <asp:DropDownList ID="DropDownList_Customer" runat="server" CssClass="form-control bnet-select" Style="padding: 10px; border-radius: 10px; background: var(--portal-card-bg); color: var(--portal-text-main); border: 1px solid var(--portal-card-border);"></asp:DropDownList>
                                    </div>

                                    <!-- Minutes to Transfer Input -->
                                    <div class="form-group" style="display: flex; flex-direction: column; gap: 6px;">
                                        <label for="<%= txtTransferMinutes.ClientID %>" style="font-size: 13px; font-weight: 700; color: var(--portal-text-main);">
                                            Minutes to Transfer <span style="color: #ef4444;">*</span>
                                        </label>
                                        <asp:TextBox ID="txtTransferMinutes" runat="server" TextMode="Number" min="1" placeholder="Enter minutes"
                                            oninput="NumberOnly(this);"
                                            onkeypress="return event.charCode >= 48 && event.charCode <= 57"
                                            CssClass="form-control" Style="padding: 10px; border-radius: 10px; background: var(--portal-card-bg); color: var(--portal-text-main); border: 1px solid var(--portal-card-border);">
                                         </asp:TextBox>
                                    </div>

                                    <asp:Button ID="btnInitTransfer" runat="server" CssClass="btn-redeem-rate" Text="Proceed to Transfer" OnClick="btnInitTransfer_Click" Style="margin-top: 8px;" />

                                    <!-- Error / Warning Message Label -->
                                    <asp:Label ID="litTransferInitError" runat="server" CssClass="text-danger" Style="color: #ef4444; font-size: 13px; display: block; margin-top: 4px; font-weight: 600;"></asp:Label>
                                </div>
                            </div>
                        </asp:Panel>

                        <!-- Redemption Confirmation Modal Popup -->
                        <asp:Panel ID="PanelRedeemModal" runat="server" CssClass="modal-backdrop-overlay" Visible="false">
                            <div class="modal-card">
                                <div class="modal-header">
                                    <i class="fa fa-star" style="color: #f59e0b;"></i>Confirm Redemption
                                </div>
                                <div class="modal-body">
                                    Are you sure you want to redeem <strong>
                                        <asp:Literal ID="litModalMinutes" runat="server"></asp:Literal>
                                        minutes</strong> for <strong>
                                            <asp:Literal ID="litModalPoints" runat="server"></asp:Literal>
                                            points</strong>?
                                </div>
                                <div class="modal-footer">
                                    <asp:Button ID="btnConfirmRedeem" runat="server" CssClass="btn-redeem-rate" Text="Yes, Redeem" OnClick="btnConfirmRedeem_Click" Style="background: #10b981;" />
                                    <asp:Button ID="btnCancelRedeem" runat="server" CssClass="btn-theme-toggle" Text="Cancel" OnClick="btnCancelRedeem_Click" Style="width: auto; padding: 8px 16px; border-radius: 10px;" />
                                </div>
                            </div>
                        </asp:Panel>

                        <!-- Insufficient Points Warning Modal Popup -->
                        <asp:Panel ID="PanelInsufficientModal" runat="server" CssClass="modal-backdrop-overlay" Visible="false">
                            <div class="modal-card">
                                <div class="modal-header">
                                    <i class="fa fa-exclamation-circle" style="color: #ef4444;"></i>Insufficient Points
                                </div>
                                <div class="modal-body">
                                    You don't have enough reward points to redeem this reward tier. Keep earning points to unlock more time!
                                </div>
                                <div class="modal-footer" style="justify-content: center;">
                                    <asp:Button ID="btnCloseInsufficientModal" runat="server" CssClass="btn-redeem-rate" Text="Okay" OnClick="btnCloseInsufficientModal_Click" Style="background: var(--portal-accent);" />
                                </div>
                            </div>
                        </asp:Panel>

                        <!-- Password Confirmation Modal for Transfer -->
                        <asp:Panel ID="PanelTransferPasswordModal" runat="server" CssClass="modal-backdrop-overlay" Visible="false">
                            <div class="modal-card">
                                <div class="modal-header">
                                    <i class="fa fa-lock" style="color: var(--portal-accent);"></i>Security Verification
                                </div>
                                <div class="modal-body">
                                    Please enter your account password to confirm transferring <strong>
                                        <asp:Literal ID="litTransferModalMins" runat="server"></asp:Literal>
                                        minutes</strong> to <strong>
                                            <asp:Literal ID="litTransferModalRecipient" runat="server"></asp:Literal></strong>.
                                    <div style="margin-top: 14px;">
                                        <asp:TextBox ID="txtTransferPassword" runat="server" TextMode="Password" placeholder="Enter your password" CssClass="form-control" Style="width: 100%; padding: 10px; border-radius: 10px; background: var(--portal-card-bg); color: var(--portal-text-main); border: 1px solid var(--portal-card-border);"></asp:TextBox>
                                        <asp:Label ID="litTransferError" runat="server" CssClass="text-danger" Style="color: #ef4444; font-size: 12px; display: block; margin-top: 6px;"></asp:Label>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <asp:Button ID="btnConfirmTransfer" runat="server" CssClass="btn-redeem-rate" Text="Confirm & Transfer" OnClick="btnConfirmTransfer_Click" Style="background: #10b981;" />
                                    <asp:Button ID="btnCancelTransfer" runat="server" CssClass="btn-theme-toggle" Text="Cancel" OnClick="btnCancelTransfer_Click" Style="width: auto; padding: 8px 16px; border-radius: 10px;" />
                                </div>
                            </div>
                        </asp:Panel>

                    </ContentTemplate>
                </asp:UpdatePanel>
            </main>
        </div>
    </form>
</body>
</html>
