<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Vouchers.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Vouchers" %>
<%@ Register Src="~/Forms/Modals/VoucherDelete.ascx" TagPrefix="uc" TagName="VoucherDelete" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:LinkButton ID="LinkButton_Refresh" runat="server"></asp:LinkButton>
        <div class="cards-grid cards-grid-compact">
            <!-- Total Vouchers Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-ticket"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Vouchers</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalTransactions" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="positive-sm">Overall</span>
            </div>

            <!-- Total Duration Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-clock"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Duration</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_Duration" runat="server" Text="0 mins"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status blue">Time</span>
            </div>

            <!-- Total Income Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-peso-sign"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Income</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_Income" runat="server" Text="₱0.00"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status yellow">Revenue</span>
            </div>
        </div>
        <div class="bnet-table-wrapper">
            <div class="bnet-table-toolbar">
                <div class="toolbar-filters">
                    <div class="search-box">
                        <asp:TextBox ID="TextBox_Search" runat="server" CssClass="search-input" AutoPostBack="True" OnTextChanged="TextBox_Search_TextChanged" placeholder="Search code, id or creator..." />
                    </div>
                    <div class="search-box" style="min-width: 200px!important">
                        <asp:DropDownList ID="DropDownList_Status" AutoPostBack="true" runat="server" CssClass="form-control bnet-select">
                            <asp:ListItem Text="FOR COLLECTION" Value="FALSE"></asp:ListItem>
                            <asp:ListItem Text="COLLECTED" Value="TRUE"></asp:ListItem>
                        </asp:DropDownList>
                    </div>
                </div>

                <asp:TextBox ID="TextBox_DateRage" AutoPostBack="true" CssClass="bnet-datepicker" data-mode="range" runat="server"></asp:TextBox>
            </div>

            <!-- Scrollable container wrapper -->
            <div class="bnet-table-container">
                <asp:GridView ID="GridViewTable" runat="server" ShowHeaderWhenEmpty="true"
                    AutoGenerateColumns="False" CssClass="bnet-table" GridLines="None"
                    AllowPaging="True" OnPageIndexChanging="GridViewTable_PageIndexChanging">

                    <PagerSettings Mode="NumericFirstLast" FirstPageText="&laquo;" LastPageText="&raquo;" PreviousPageText="&lsaquo;" NextPageText="&rsaquo;" PageButtonCount="5" />
                    <PagerStyle CssClass="bnet-pagination" HorizontalAlign="Center" />

                    <Columns>
                        <asp:TemplateField HeaderText="Action" ItemStyle-Width="120px">
                            <ItemTemplate>
                                <div class="bnet-dropdown" tabindex="0">
                                    <button type="button" class="bnet-dropdown-toggle">
                                        Command <i class="fa-solid fa-chevron-down"></i>
                                    </button>
                                    <div class="bnet-dropdown-menu">
                                        <a onclick="openVoucherDeleteModal('<%# Eval("DBId") %>', '<%# Eval("DBCode") %>')" class="bnet-dropdown-item text-danger">
                                            <i class="fa-solid fa-trash"></i>Delete
                                        </a>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Voucher Code" ItemStyle-Width="220px">
                            <ItemTemplate>
                                <span class="bnet-badge-status blue">
                                    <asp:Label ID="Label_DBCode" runat="server" Text='<%# Eval("DBCode") %>'></asp:Label>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Id" ItemStyle-Width="180px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBId" runat="server" Text='<%# Eval("DBId") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Duration" ItemStyle-Width="150px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBFormattedDuration" runat="server" Text='<%# Eval("DBFormattedDuration") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Amount Paid" ItemStyle-Width="150px">
                            <ItemTemplate>
                                <span class="bnet-badge-status yellow">
                                    <asp:Label ID="Label_DBAmount" runat="server" Text='<%# string.Format("₱{0}", Eval("DBAmount")) %>'></asp:Label>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Collected" ItemStyle-Width="140px">
                            <ItemTemplate>
                                <span class='<%# Eval("DBIsCollected").ToString() == "TRUE" ? "bnet-badge-status green" : "bnet-badge-status gray" %>'>
                                    <asp:Label ID="Label_DBIsCollected" runat="server" Text='<%# Eval("DBIsCollected") %>'></asp:Label>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Created By" ItemStyle-Width="160px">
                            <ItemTemplate>
                                <span class='<%# Eval("DBCreatedByName").ToString() == "System / Unknown" ? "bnet-badge-status gray" : "bnet-badge-status green" %>'>
                                    <asp:Label ID="Label_DBCreatedByName" runat="server" Text='<%# Eval("DBCreatedByName") %>'></asp:Label>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Date & Time Created" ItemStyle-Width="220px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBDateCreated_DBTimeCreated" runat="server" Text='<%# string.Format("{0} - {1}", Eval("DBDateCreated"), Eval("DBTimeCreated")) %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Deleted By" ItemStyle-Width="160px">
                            <ItemTemplate>
                                <span class='<%# Eval("DBDeletedByName").ToString() == "--" ? "bnet-badge-status gray" : "bnet-badge-status red" %>'>
                                    <asp:Label ID="Label_DBDeletedByName" runat="server" Text='<%# Eval("DBDeletedByName") %>'></asp:Label>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Date & Time Deleted" ItemStyle-Width="220px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBDateDeleted_DBTimeDeleted" runat="server" Text='<%# string.IsNullOrEmpty(Eval("DBDateDeleted") as string) ? "--" : string.Format("{0} - {1}", Eval("DBDateDeleted"), Eval("DBTimeDeleted")) %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
            <asp:Panel ID="Panel_Pagination" runat="server" />
        </div>

        <uc:VoucherDelete runat="server" ID="VoucherDeleteModal" />
    </ContentTemplate>
</asp:UpdatePanel>