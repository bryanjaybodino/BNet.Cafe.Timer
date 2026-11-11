<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="UserBonus.ascx.cs" Inherits="BNet.Cafe.Server.Forms.UserBonus" %>
<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:HiddenField ID="HiddenField_Role" runat="server" />
        <asp:Panel ID="Panel_Form" runat="server">
            <div class="bnet-table-wrapper" style="width: 100%; padding: 14px;">

                <!-- Header -->
                <div class="content-header" style="margin-bottom: 14px; border-bottom: 1px solid var(--border-light); padding-bottom: 16px;">
                    <h1 style="display: flex; align-items: center; gap: 10px; font-size: 20px; font-weight: 700; color: var(--text-light);">
                        <i class="fa-solid fa-wallet" style="color: var(--primary);"></i>
                        Bonus Credit
                    </h1>
                    <p style="color: var(--text-light-secondary); font-size: 14px; margin-top: 4px;">
                        Enter bonus credit for your loyal member.
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
                    <div class="form-group">
                        <label for="<%= TextBox_Amount.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Amount Paid (₱) <span style="color: #ef4444; font-weight: 700;">*</span></label>
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
                            <span class="card-title-sm" style="display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); margin-bottom: 4px; font-weight: 600;">Formatted Credit Time</span>
                            <strong id="display_FormattedTime" style="font-size: 1.75rem; color: var(--primary); font-weight: 700;">0 hrs 0 mins</strong>
                        </div>
                        <div style="text-align: right;">
                            <span class="card-title-sm" style="display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-light-secondary); margin-bottom: 4px; font-weight: 600;">Total Charge</span>
                            <strong id="display_TotalAmount" style="font-size: 1.75rem; color: #10b981; font-weight: 700;">₱ 0.00</strong>
                        </div>
                    </div>
                </div>

                <!-- Description / Remarks -->
                <div class="form-group" style="margin-bottom: 20px;">
                    <label for="<%= TextBox_Description.ClientID %>" style="display: block; font-weight: 600; font-size: 14px; margin-bottom: 8px; color: var(--text-light);">Description / Remarks</label>
                    <asp:TextBox ID="TextBox_Description" runat="server" Enabled="false" CssClass="form-control" Text="Bonus Credit" Style="width: 100%;"></asp:TextBox>
                </div>

                <!-- Footer Layout: Active Session Note & Action Buttons -->
                <div style="display: flex; justify-content: space-between; align-items: center; gap: 16px; border-top: 1px solid var(--border-light); padding-top: 20px; flex-wrap: wrap;">
                    
                    <!-- Notice regarding currently logged-in users -->
                    <div style="font-size: 12px; color: #f59e0b; display: flex; align-items: center; gap: 6px; background: rgba(245, 158, 11, 0.1); padding: 8px 12px; border-radius: 6px; border: 1px solid rgba(245, 158, 11, 0.2);">
                        <i class="fa-solid fa-circle-info"></i>
                        <span><strong>Note:</strong> If the user is currently logged in, the added bonus time will not automatically reflect on their active session.</span>
                    </div>

                    <!-- Action Buttons -->
                    <div style="display: flex; gap: 12px; margin-left: auto;">
                        <span onclick="navigateTo('BNetPage.aspx?Form=Users')" class="btn btn-secondary" style="cursor: pointer; display: inline-flex; align-items: center;">
                            <i class="fa-solid fa-arrow-left"></i>Back
                        </span>
                        <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click" CssClass="btn btn-primary" OnClientClick="return ValidateTopUp();" runat="server" Style="display: inline-flex; align-items: center;">
                            <i class="fa-solid fa-circle-check"></i> Process Top-Up
                        </asp:LinkButton>
                    </div>

                </div>

            </div>
        </asp:Panel>
    </ContentTemplate>
</asp:UpdatePanel>