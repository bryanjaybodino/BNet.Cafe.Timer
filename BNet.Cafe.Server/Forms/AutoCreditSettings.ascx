<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AutoCreditSettings.ascx.cs" Inherits="BNet.Cafe.Server.Forms.AutoCreditSettings" %>
<%@ Register Src="~/Forms/Modals/AutoCreditSettingDelete.ascx" TagPrefix="uc1" TagName="AutoCreditSettingDelete" %>


<asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional">
    <ContentTemplate>
        <asp:HiddenField ID="HiddenField_AutoCreditId" runat="server" Value="0" />

        <div class="pricing-settings-wrapper">
            <!-- Quick Reference -->
            <div class="quick-reference">
                <h3>💡 Auto Credit Rates Quick Reference</h3>
                <p>
                    Set fixed points rewarded for specific auto credit rules based on customer tier and trigger conditions.
                </p>
            </div>

            <!-- Main Content Grid -->
            <div class="pricing-container">
                <!-- Left: Form Panel -->
                <div class="pricing-form-panel">
                    <div class="form-card">
                        <h2 class="form-section-title" style="padding-bottom: 25px">
                            <i class="fa-solid fa-plus-circle"></i>Add/Edit Auto Credit Rate
                        </h2>

                        <!-- Credit Name -->
                        <div class="form-group">
                            <label for="TextBox_CreditName">
                                Credit Name <span class="required-badge">*</span>
                            </label>
                            <asp:TextBox ID="TextBox_CreditName" runat="server" CssClass="form-control pricing-input"
                                placeholder="Enter Credit Name"></asp:TextBox>
                        </div>

                        <!-- Customer Type -->
                        <div class="form-group">
                            <label for="DropDownList_CustomerType">
                                Customer Tier <span class="required-badge">*</span>
                            </label>
                            <asp:DropDownList ID="DropDownList_CustomerType" AutoPostBack="true" runat="server" CssClass="form-control bnet-select">
                                <asp:ListItem Text="Member" Value="MEMBER"></asp:ListItem>
                                <asp:ListItem Text="VIP" Value="VIP"></asp:ListItem>
                            </asp:DropDownList>
                        </div>

                        <!-- Trigger Date -->
                        <div class="form-group">
                            <label for="TextBox_TriggerDate">
                                Trigger Date <span class="required-badge">*</span>
                            </label>
                            <asp:TextBox ID="TextBox_TriggerDate" runat="server" CssClass="bnet-datepicker" data-mode="monthday" placeholder="Select trigger month & day..."></asp:TextBox>
                        </div>

                        <!-- Points -->
                        <div class="form-group">
                            <label for="TextBox_Points">
                                Points <span class="required-badge">*</span>
                            </label>
                            <div class="input-group-with-helper">
                                <div class="price-input-wrapper">
                                    <span class="currency-symbol"><i class="fa fa-star" style="font-size: 13px; color: var(--primary);"></i></span>
                                    <asp:TextBox ID="TextBox_Points" runat="server" TextMode="Number" CssClass="form-control pricing-input"
                                        placeholder="0.00" step="0.01" min="0" Style="padding-left: 36px;"></asp:TextBox>
                                </div>
                            </div>
                        </div>

                        <!-- Action Buttons -->
                        <div class="form-actions">
                            <asp:LinkButton ID="LinkButton_Cancel" OnClick="LinkButton_Cancel_Click"
                                CssClass="btn btn-secondary" runat="server">
                                <i class="fa fa-times-circle"></i> Clear
                            </asp:LinkButton>
                            <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click"
                                CssClass="btn btn-primary btn-lg" OnClientClick="return ValidateAutoCreditRule();" runat="server">
                                <i class="fa fa-save"></i> Save Rate
                            </asp:LinkButton>
                        </div>
                        <br />
                        <br />
                        <br />
                    </div>
                </div>

                <!-- Right: Data Grid Panel -->
                <div class="pricing-grid-panel">
                    <div class="grid-card">
                        <div class="grid-header">
                            <h2 class="grid-title">
                                <i class="fa-solid fa-list"></i>Existing Auto Credit Rates
                            </h2>
                            <span class="grid-count">Total: <strong id="RuleCount">
                                <asp:Label ID="Label_TotalRules" runat="server" Text="0"></asp:Label>
                            </strong>rates
                            </span>
                        </div>

                        <!-- Grid Container -->
                        <div class="bnet-table-container pricing-grid-container">
                            <asp:GridView ID="GridView_AutoCredit" runat="server" AutoGenerateColumns="False" GridLines="None"
                                CssClass="bnet-table pricing-table">
                                <Columns>
                                    <asp:TemplateField HeaderText="Credit Name">
                                        <HeaderStyle Width="25%" CssClass="header-cell" />
                                        <ItemStyle Width="25%" CssClass="cell-duration" />
                                        <ItemTemplate>
                                            <span class="duration-value"><%# Eval("DBCreditName") %></span>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Tier">
                                        <HeaderStyle Width="15%" CssClass="header-cell" />
                                        <ItemStyle Width="15%" CssClass="cell-tier" />
                                        <ItemTemplate>
                                            <span class="tier-badge">
                                                <%# Eval("DBCustomerType") %>
                                            </span>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Trigger Date">
                                        <HeaderStyle Width="20%" CssClass="header-cell" />
                                        <ItemStyle Width="20%" CssClass="cell-duration" />
                                        <ItemTemplate>
                                            <span class="duration-minutes"><%# Eval("DBTriggerDate") %></span>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Points">
                                        <HeaderStyle Width="20%" CssClass="header-cell" />
                                        <ItemStyle Width="20%" CssClass="cell-price" />
                                        <ItemTemplate>
                                            <span class="price-value">
                                                <%# double.Parse(Eval("DBPoints").ToString()).ToString("F2") %> pts
                                            </span>
                                        </ItemTemplate>
                                    </asp:TemplateField>

                                    <asp:TemplateField HeaderText="Actions">
                                        <HeaderStyle Width="20%" CssClass="header-cell" />
                                        <ItemStyle Width="20%" CssClass="cell-actions" />
                                        <ItemTemplate>
                                            <div class="action-buttons">
                                                <button type="button"
                                                    class="btn-action btn-edit"
                                                    title="Edit this rate"
                                                    data-id='<%# Eval("DBId") %>'
                                                    data-creditname='<%# Eval("DBCreditName") %>'
                                                    data-tier='<%# Eval("DBCustomerType") %>'
                                                    data-triggerdate='<%# Eval("DBTriggerDate") %>'
                                                    data-points='<%# Eval("DBPoints") %>'
                                                    onclick="editAutoCreditRule(this)">
                                                    <i class="fa fa-edit"></i>
                                                </button>
                                                <button type="button"
                                                    class="btn-action btn-delete"
                                                    title="Delete this credit rate"
                                                    onclick="openAutoCreditDeleteModal('<%# Eval("DBId") %>', '<%# Eval("DBCreditName") %> (<%# Eval("DBCustomerType") %>)')">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </div>
                                        </ItemTemplate>
                                    </asp:TemplateField>
                                </Columns>
                                <EmptyDataTemplate>
                                    <div class="empty-state">
                                        <i class="fa-solid fa-inbox"></i>
                                        <p>No auto credit rates defined yet.</p>
                                        <small>Create your first rate to get started.</small>
                                    </div>
                                </EmptyDataTemplate>
                            </asp:GridView>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <uc1:AutoCreditSettingDelete runat="server" ID="AutoCreditSettingDelete" />
    </ContentTemplate>
</asp:UpdatePanel>
