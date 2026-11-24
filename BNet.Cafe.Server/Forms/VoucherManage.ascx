<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="VoucherManage.ascx.cs" Inherits="BNet.Cafe.Server.Forms.VoucherManage" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:HiddenField ID="HiddenField_Role" runat="server" />
        <asp:HiddenField ID="HiddenField_ClientName" runat="server" Value="" />

        <asp:Panel ID="Panel_Form" runat="server">
            <div class="bnet-table-wrapper">
                <div class="content-header" style="margin-bottom: 20px;">
                    <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-ticket" style="color: var(--primary);"></i>
                        <span>Voucher Management</span>
                    </h1>
                    <p>Calculate voucher duration and amount via pricing handler, generate a voucher code, and print via RDLC report.</p>
                </div>

                <!-- Interactive Duration Controls -->
                <div class="duration-section">
                    <label>Duration Quick Actions</label>
                    <div class="quick-btn-group">
                        <button type="button" class="btn btn-secondary" onclick="adjustVoucherDuration(15)">+15 Mins</button>
                        <button type="button" class="btn btn-secondary" onclick="adjustVoucherDuration(30)">+30 Mins</button>
                        <button type="button" class="btn btn-secondary" onclick="adjustVoucherDuration(60)">+1 Hour</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustVoucherDuration(-15)">-15 Mins</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustVoucherDuration(-30)">-30 Mins</button>
                        <button type="button" class="btn btn-danger-outline" onclick="adjustVoucherDuration(-60)">-1 Hour</button>
                        <button type="button" class="btn btn-danger-outline" onclick="resetVoucherDuration()">Reset</button>
                    </div>

                    <div class="form-grid" style="margin-top: 15px;">
                        <div class="form-group">
                            <label for="<%= TextBox_Duration.ClientID %>">Total Input (Minutes) <span style="color: #ef4444;">*</span></label>
                            <asp:TextBox ID="TextBox_Duration" runat="server" CssClass="form-control" placeholder="Enter mins (e.g. 60)" TextMode="Number" min="0" oninput="if (typeof NumberOnly === 'function') { NumberOnly(this); } else { this.value = this.value.replace(/[^0-9]/g, ''); } calculateVoucherAmount();"></asp:TextBox>
                        </div>
                        <div class="form-group">
                            <label for="<%= TextBox_Amount.ClientID %>">Total Input Amount (₱) <span style="color: #ef4444;">*</span></label>
                            <asp:TextBox ID="TextBox_Amount" runat="server" CssClass="form-control" placeholder="Enter amount (e.g. 20)" TextMode="Number" min="0" step="0.01" oninput="if (typeof NumberOnly === 'function') { NumberOnly(this); } else { this.value = this.value.replace(/[^0-9.]/g, ''); } calculateVoucherTimeFromAmount();"></asp:TextBox>
                        </div>
                    </div>

                    <div style="display: none;">
                        <asp:TextBox ID="TextBox_TotalDuration" runat="server"></asp:TextBox>
                        <asp:TextBox ID="TextBox_TotalAmount" runat="server"></asp:TextBox>
                    </div>
                </div>

                <!-- Highlighted Summary Display Box -->
                <div class="summary-display-card">
                    <div class="summary-item">
                        <span class="summary-label"><i class="fa-solid fa-hourglass-half"></i>Total Time</span>
                        <span id="display_VoucherFormattedTime" class="summary-value highlight-time">0 hrs 0 mins</span>
                        <small id="display_VoucherTimeBreakdown" style="display: none; color: #6b7280; font-size: 12px; margin-top: 4px;"></small>
                    </div>
                    <div class="summary-divider"></div>
                    <div class="summary-item">
                        <span class="summary-label"><i class="fa-solid fa-peso-sign"></i>Total Amount</span>
                        <span id="display_VoucherTotalAmount" class="summary-value highlight-amount">₱ 0.00</span>
                        <small id="display_VoucherAmountBreakdown" style="display: none; color: #10b981; font-size: 12px; font-weight: 600; margin-top: 4px;"></small>
                    </div>
                </div>

                <div class="form-grid-action">
                    <asp:LinkButton ID="LinkButton_CreateVoucher" OnClick="LinkButton_CreateVoucher_Click" CssClass="btn btn-primary" OnClientClick="return validateVoucherForm();" runat="server">
                        <i class="fa-solid fa-plus"></i> Add &amp; Print Voucher
                    </asp:LinkButton>
                </div>
            </div>
        </asp:Panel>

        <asp:Panel ID="Panel_PriceSettingAlert" Visible="false" runat="server" Style="background: linear-gradient(135deg, var(--bg-light) 0%, var(--bg-light-tertiary) 100%); border: 1px solid var(--border-light); border-radius: 12px; padding: 24px; margin-top: 20px; text-align: center; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02);">
            <div style="display: flex; flex-direction: column; align-items: center; gap: 12px; margin-bottom: 20px;">
                <div style="width: 48px; height: 48px; background-color: var(--bg-light-secondary); color: var(--accent-pingpong); border: 1px solid var(--border-light); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04);">
                    <i class="fa-solid fa-triangle-exclamation"></i>
                </div>
                <div>
                    <h3 style="font-size: 16px; font-weight: 600; color: var(--text-light); margin: 0 0 4px 0;">Configuration Required</h3>
                    <p style="font-size: 14px; color: var(--text-light-secondary); margin: 0;">No active pricing rates found. Please configure your rates to enable voucher calculations.</p>
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

        <!-- Latest 10 Vouchers Table -->
        <div class="bnet-table-wrapper" style="margin-top: 24px;">
            <div class="content-header" style="margin-bottom: 14px;">
                <h2 style="font-size: 17px; margin: 0; display: flex; align-items: center; gap: 8px;">
                    <i class="fa-solid fa-clock-rotate-left" style="color: var(--primary);"></i>
                    <span>Latest 10 Vouchers</span>
                </h2>
                <p style="margin: 2px 0 0 0; font-size: 13px;">Recent vouchers ready to copy or print.</p>
            </div>

            <div class="bnet-table-container">
                <asp:GridView ID="GridView_LatestVouchers" runat="server" ShowHeaderWhenEmpty="true"
                    AutoGenerateColumns="False" CssClass="bnet-table" GridLines="None"
                    OnRowCommand="GridView_LatestVouchers_RowCommand">
                    <Columns>
                        <asp:TemplateField HeaderText="Action" ItemStyle-Width="210px">
                            <ItemTemplate>
                                <div class="voucher-row-actions" style="display: inline-flex; align-items: center; gap: 6px; flex-wrap: nowrap; white-space: nowrap;">
                                    <asp:LinkButton ID="LinkButton_PrintRow" runat="server"
                                        CommandName="PrintVoucher"
                                        CommandArgument='<%# Eval("DBId") %>'
                                        CssClass="btn btn-secondary"
                                        Style="display: inline-flex; align-items: center; gap: 4px; padding: 6px 10px; font-size: 12px; white-space: nowrap;">
                                        <i class="fa-solid fa-print"></i> Print
                                    </asp:LinkButton>
                                    <button type="button"
                                        class="btn btn-secondary"
                                        style="display: inline-flex; align-items: center; gap: 4px; padding: 6px 10px; font-size: 12px; white-space: nowrap;"
                                        onclick="copyVoucherCode('<%# Eval("DBCode") %>')">
                                        <i class="fa-solid fa-copy"></i> Copy
                                    </button>
                                </div>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Voucher Code" ItemStyle-Width="250px">
                            <ItemTemplate>
                                <span class="bnet-badge-status blue voucher-code-badge">
                                    <%# Eval("DBCode") %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="ID" ItemStyle-Width="80px">
                            <ItemTemplate>
                                <asp:Label ID="Label_RowId" runat="server" Text='<%# Eval("DBId") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Duration" ItemStyle-Width="140px">
                            <ItemTemplate>
                                <asp:Label ID="Label_RowDuration" runat="server" Text='<%# Eval("DBFormattedDuration") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Amount" ItemStyle-Width="130px">
                            <ItemTemplate>
                                <span class="bnet-badge-status yellow">₱<%# Eval("DBAmount") %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Status" ItemStyle-Width="140px">
                            <ItemTemplate>
                                <span class='<%# Eval("DBIsCollected").ToString() == "TRUE" ? "bnet-badge-status green" : "bnet-badge-status gray" %>'>
                                    <%# Eval("DBIsCollected").ToString() == "TRUE" ? "COLLECTED" : "FOR COLLECTION" %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Created By" ItemStyle-Width="150px">
                            <ItemTemplate>
                                <asp:Label ID="Label_RowCreator" runat="server" Text='<%# Eval("DBCreatedByName") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Date &amp; Time Created" ItemStyle-Width="200px">
                            <ItemTemplate>
                                <%# string.Format("{0} - {1}", Eval("DBDateCreated"), Eval("DBTimeCreated")) %>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>