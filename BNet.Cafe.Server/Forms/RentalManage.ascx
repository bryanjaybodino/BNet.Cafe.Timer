<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="RentalManage.ascx.cs" Inherits="BNet.Cafe.Server.Forms.RentalManage" %>
<%@ Register Src="~/Forms/Modals/RemoteOpenTime.ascx" TagPrefix="uc1" TagName="RemoteOpenTime" %>
<%-- Change 1: Update register directive prefix and tag name --%>
<%@ Register Src="~/Forms/Modals/RemoteEditTime.ascx" TagPrefix="uc2" TagName="RemoteEditTime" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <!-- Hidden fields to store loaded DB state -->
        <asp:HiddenField ID="HiddenField_InitialDuration" runat="server" Value="0" />
        <asp:HiddenField ID="HiddenField_InitialAmount" runat="server" Value="0.00" />
        <asp:HiddenField ID="HiddenField_Role" runat="server" />
        <asp:Panel ID="Panel_Form" runat="server">
            <div class="bnet-table-wrapper">
                <div class="content-header" style="margin-bottom: 20px;">
                    <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-clock" style="color: var(--primary);"></i>
                        <asp:Label ID="Label_HeaderText" runat="server" Text=""></asp:Label>
                        <asp:Label ID="Label_RentalId" runat="server" Text=""></asp:Label>
                        <asp:Label ID="Label_Status" runat="server" Text=""></asp:Label>
                    </h1>
                    <p>Select customer details, manage rental duration, and calculate charges.</p>
                </div>

                <div class="form-grid">
                    <!-- Computer Selection -->
                    <div class="form-group">
                        <label for="<%= TextBox_ComputerName.ClientID %>">Computer <span style="color: #ef4444;">*</span></label>
                        <asp:TextBox ID="TextBox_ComputerName" Enabled="false" runat="server" CssClass="form-control" placeholder="e.g., PC-01" MaxLength="50"></asp:TextBox>
                    </div>

                    <!-- Customer Selection -->
                    <div class="form-group">
                        <label for="<%= DropDownList_Customer.ClientID %>">Customer <span style="color: #ef4444;">*</span></label>
                        <asp:DropDownList ID="DropDownList_Customer" Enabled="false" runat="server" CssClass="form-control bnet-select"></asp:DropDownList>
                    </div>
                </div>

                <!-- Interactive Duration Controls -->
                <div class="duration-section">
                    <label>Duration Quick Actions</label>
                    <div class="quick-btn-group">
                        <button type="button" class="btn btn-secondary" onclick="adjustDuration(15)">+15 Mins</button>
                        <button type="button" class="btn btn-secondary" onclick="adjustDuration(30)">+30 Mins</button>
                        <button type="button" class="btn btn-secondary" onclick="adjustDuration(60)">+1 Hour</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustDuration(-15)">-15 Mins</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustDuration(-30)">-30 Mins</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustDuration(-60)">-1 Hour</button>
                        <button type="button" class="btn btn-danger-outline" onclick="resetDuration()">Reset</button>
                    </div>

                    <div class="form-grid" style="margin-top: 15px;">
                        <div class="form-group">
                            <label for="<%= TextBox_Duration.ClientID %>">Total Input (Minutes)</label>
                            <asp:TextBox ID="TextBox_Duration" runat="server" CssClass="form-control" placeholder="Enter extra mins (e.g. 30)" TextMode="Number" min="0" oninput="NumberOnly(this); calculateAmount();"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label for="<%= TextBox_Amount.ClientID %>">Total Input Amount (₱)</label>
                            <asp:TextBox ID="TextBox_Amount" runat="server" CssClass="form-control" placeholder="Enter extra amount (e.g. 20)" TextMode="Number" oninput="NumberOnly(this); calculateTimeFromAmount();"></asp:TextBox>
                        </div>
                    </div>
                </div>
                <div style="display: none;">
                    <asp:TextBox ID="TextBox_TotalAmount" runat="server"></asp:TextBox>
                    <asp:TextBox ID="TextBox_TotalDuration" runat="server"></asp:TextBox>
                </div>

                <!-- Highlighted Summary Display Box -->
                <div class="summary-display-card">
                    <div class="summary-item">
                        <span class="summary-label"><i class="fa-solid fa-hourglass-half"></i>Total Time</span>
                        <span id="display_FormattedTime" class="summary-value highlight-time">0 hrs 0 mins</span>
                        <small id="display_TimeBreakdown" style="display: none; color: #6b7280; font-size: 12px; margin-top: 4px;"></small>
                    </div>
                    <div class="summary-divider"></div>
                    <div class="summary-item">
                        <span class="summary-label"><i class="fa-solid fa-peso-sign"></i>Total Amount</span>
                        <span id="display_TotalAmount" class="summary-value highlight-amount">₱ 0.00</span>
                        <small id="display_AmountBreakdown" style="display: none; color: #10b981; font-size: 12px; font-weight: 600; margin-top: 4px;"></small>
                    </div>
                </div>

                <asp:Panel ID="Panel_Buttons" runat="server">
                    <!-- Form Actions -->
                    <div class="form-grid-action">
                        <span onclick="navigateTo('BNetPage.aspx?Form=Computers')" class="btn btn-secondary">Back</span>
                        
                        <!-- Change 2: Update JS function call to openRemoteEditTimeModal -->
                        <span type="button" class="btn btn-secondary" onclick="openRemoteEditTimeModal('<%= Label_RentalId.Text %>', document.getElementById('<%= HiddenField_InitialDuration.ClientID %>').value, document.getElementById('<%= HiddenField_InitialAmount.ClientID %>').value)" style="padding: 8px 12px;">
                            <i class="fa-solid fa-pen-to-square"></i> Edit
                        </span>

                        <span id="LinkButton_OpenTime" runat="server">
                            <a class="btn btn-danger" onclick="openOpenTimeModal('<%= Label_RentalId.Text %>','<%= TextBox_ComputerName.Text %>','<%= DropDownList_Customer.SelectedValue %>','<%= Label_Status.Text %>')"><i class="fa fa-hourglass"></i>Open Time</a>
                        </span>
                        <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click" CssClass="btn btn-primary" OnClientClick="return Validate();" runat="server">
                            <i class="fa fa-save"></i>Add Rental
                        </asp:LinkButton>
                    </div>
                </asp:Panel>
            </div>
        </asp:Panel>
        <asp:Panel ID="Panel_PriceSettingAlert" Visible="false" runat="server" Style="background: linear-gradient(135deg, var(--bg-light) 0%, var(--bg-light-tertiary) 100%); border: 1px solid var(--border-light); border-radius: 12px; padding: 24px; margin-top: 20px; text-align: center; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);">
            <div style="display: flex; flex-direction: column; align-items: center; gap: 12px; margin-bottom: 20px;">
                <div style="width: 48px; height: 48px; background-color: var(--bg-light-secondary); color: var(--accent-pingpong); border: 1px solid var(--border-light); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04);">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <div>
                    <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin: 0 0 4px 0;">Configuration Required</h3>
                    <p style="font-size: 14px; color: var(--text-light-secondary); margin: 0;">No active pricing rates found. Please configure your rates to enable rental duration calculations and checkout options.</p>
                </div>
            </div>
            <div style="max-width: 320px; margin: 0 auto;">
                <asp:HyperLink ID="HyperLink_PriceSettings" runat="server"
                    CssClass="btn btn-primary"
                    Style="width: 100%; text-align: center; justify-content: center; display: inline-flex; align-items: center; gap: 8px;"
                    onclick="navigateTo('?Form=PricingSettings'); return false;">
                    <i class="fa-solid fa-gear"></i> Create Your Price Setting First
                </asp:HyperLink>
            </div>
        </asp:Panel>
        <%-- Change 3: Update control ID/Tag --%>
        <uc2:RemoteEditTime runat="server" ID="RemoteEditTime" />
        <uc1:RemoteOpenTime runat="server" ID="RemoteOpenTime" />
    </ContentTemplate>
</asp:UpdatePanel>