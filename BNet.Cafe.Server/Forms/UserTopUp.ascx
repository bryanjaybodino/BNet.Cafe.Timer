<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="UserTopUp.ascx.cs" Inherits="BNet.Cafe.Server.Forms.UserTopUp" %>
<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:HiddenField ID="HiddenField_Role" runat="server" />
        <asp:Panel ID="Panel_Form" runat="server">
            <div class="bnet-table-wrapper" style="width: 100%; padding: 14px;">

                <!-- Header -->
                <div class="content-header" style="margin-bottom: 14px; border-bottom: 1px solid var(--border-light); padding-bottom: 16px;">
                    <h1 style="display: flex; align-items: center; gap: 10px; font-size: 20px; font-weight: 700; color: var(--text-light);">
                        <i class="fa-solid fa-wallet" style="color: var(--primary);"></i>
                        Top-Up & Deduction
                    </h1>
                    <p style="color: var(--text-light-secondary); font-size: 14px; margin-top: 4px;">
                        Manage user balance by adding top-up credits or deducting balance securely.
                    </p>
                </div>

                <!-- User Details Banner -->
                <div class="card card-compact" style="display: flex; justify-content: space-between; align-items: center; background: var(--bg-light-secondary); border: 1px solid var(--border-light); border-radius: 12px; padding: 18px 20px; margin-bottom: 14px; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                    <div class="card-inline-content" style="display: flex; align-items: center; gap: 14px;">
                        <div class="card-icon-sm" style="width: 44px; height: 44px; border-radius: 10px; background: var(--bg-light-tertiary); color: var(--primary); display: flex; align-items: center; justify-content: center; font-size: 1.2rem;">
                            <i class="fa-solid fa-user"></i>
                        </div>
                        <div class="card-details" style="display: flex; flex-direction: column;">
                            <span class="card-title-sm" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); font-weight: 600;">Account User</span>
                            <span class="card-value-sm" style="font-size: 16px; font-weight: 600; color: var(--text-light); margin: 2px 0;">
                                <asp:Label ID="Label_UserName" runat="server" Text="Loading User..."></asp:Label>
                            </span>
                            <span class="card-footer" style="font-size: 12px; color: var(--text-light-secondary);">
                                <asp:Label ID="Label_UserEmail" runat="server" Text="--"></asp:Label>
                            </span>
                        </div>
                    </div>
                    <div class="card-details" style="text-align: right; background: var(--bg-light-tertiary); padding: 10px 16px; border-radius: 8px; border: 1px solid var(--border-light);">
                        <span class="card-title-sm" style="font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); font-weight: 600; display: block; margin-bottom: 2px;">Current Balance</span>
                        <span class="card-value-sm" style="font-size: 20px; font-weight: 700; color: var(--primary);">
                            <asp:Label ID="Label_CurrentBalance" runat="server" Text="0 Mins"></asp:Label>
                        </span>
                    </div>
                </div>

                <!-- Form Inputs Grid -->
                <div class="form-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 20px;">
                    <div class="form-group" style="grid-column: 1 / -1;">
                        <label for="<%= DropDownList_Type.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Transaction Type</label>
                        <asp:DropDownList ID="DropDownList_Type" runat="server" CssClass="form-control bnet-select" AutoPostBack="true" OnSelectedIndexChanged="DropDownList_Type_SelectedIndexChanged" Style="width: 100%;">
                            <asp:ListItem Text="Top-Up (Add Credit)" Value="TopUp" Selected="True" />
                            <asp:ListItem Text="Deduction (Subtract Balance)" Value="Deduction" />
                        </asp:DropDownList>
                    </div>

                    <div class="form-group">
                        <label for="<%= TextBox_Amount.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Amount (₱) <span style="color: #ef4444; font-weight: 700;">*</span></label>
                        <asp:TextBox ID="TextBox_Amount" runat="server" CssClass="form-control" Text="0.00" TextMode="Number" step="0.01" min="0" oninput="NumberOnly(this); calculateTimeFromAmount();" Style="width: 100%;"></asp:TextBox>
                    </div>

                    <div class="form-group">
                        <label for="<%= TextBox_Duration.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Equivalent Duration (Minutes)</label>
                        <asp:TextBox ID="TextBox_Duration" runat="server" CssClass="form-control" Text="0" TextMode="Number" min="0" oninput="NumberOnly(this); calculateAmountFromTime();" Style="width: 100%;"></asp:TextBox>
                    </div>
                </div>

                <!-- Conversion Preview Card -->
                <div class="card" style="background: var(--bg-light-secondary); border: 1px solid var(--border-light); border-radius: 12px; margin-bottom: 20px; padding: 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                        <div>
                            <span class="card-title-sm" style="display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); margin-bottom: 4px; font-weight: 600;">Formatted Credit/Deduct Time</span>
                            <strong id="display_FormattedTime" style="font-size: 1.75rem; color: var(--primary); font-weight: 700;">0 hrs 0 mins</strong>
                        </div>
                        <div style="text-align: right;">
                            <span class="card-title-sm" style="display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); margin-bottom: 4px; font-weight: 600;">Total Charge/Deduction</span>
                            <strong id="display_TotalAmount" style="font-size: 1.75rem; color: #10b981; font-weight: 700;">₱ 0.00</strong>
                        </div>
                    </div>
                </div>

                <!-- Description / Remarks -->
                <div class="form-group" style="margin-bottom: 14px; display: none">
                    <label for="<%= TextBox_Description.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Description / Remarks</label>
                    <asp:TextBox ID="TextBox_Description" runat="server" Enabled="false" CssClass="form-control" Text="Top-Up Load Credit" Style="width: 100%;"></asp:TextBox>
                </div>

                <!-- Footer Layout: Critical Red Warning Panel with Button beside action buttons -->
                <div style="display: flex; justify-content: space-between; align-items: center; gap: 16px; border-top: 1px solid var(--border-light); padding-top: 20px; flex-wrap: wrap;">

                    <!-- Active Session Warning Panel (Critical Red Theme with Button) -->
                    <asp:Panel ID="Panel_ActiveSessionWarning" runat="server" Visible="false" CssClass="card" Style="background-color: rgba(239, 68, 68, 0.08); border: 1px solid #f87171; border-left: 4px solid #ef4444; border-radius: 8px; padding: 12px 16px; flex: 1; min-width: 300px; margin-bottom: 0;">
                        <div style="display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <i class="fa-solid fa-triangle-exclamation" style="font-size: 1.2rem; color: #ef4444;"></i>
                                <div style="font-size: 13px; color: #991b1b;">
                                    <strong style="font-weight: 600; display: block; color: #7f1d1d;">User Already Logged In</strong>
                                    Active session detected.
                                </div>
                            </div>
                            <asp:HyperLink ID="HyperLink_ViewRental" runat="server" CssClass="btn btn-danger" Style="padding: 6px 12px; font-size: 12px; display: inline-flex; align-items: center; gap: 6px; text-decoration: none;">
                                <i class="fa-solid fa-desktop"></i>Manage
                                <asp:Label ID="Label_LoggedInClientName" runat="server" Text="PC-01"></asp:Label>
                            </asp:HyperLink>
                        </div>
                    </asp:Panel>

                    <!-- Action Buttons -->
                    <div class="form-grid-action" style="display: flex; gap: 12px; margin-top: 0; padding-top: 0; border-top: none; margin-left: auto;">
                        <span onclick="navigateTo('BNetPage.aspx?Form=Users')" class="btn btn-secondary" style="cursor: pointer; display: inline-flex; align-items: center;">
                            <i class="fa-solid fa-arrow-left"></i>Back
                        </span>
                        <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click" CssClass="btn btn-primary" OnClientClick="return ValidateTopUp();" runat="server" Style="display: inline-flex; align-items: center;">
                            <i class="fa-solid fa-circle-check"></i> Process Transaction
                        </asp:LinkButton>
                    </div>

                </div>

            </div>
        </asp:Panel>
    </ContentTemplate>
</asp:UpdatePanel>
