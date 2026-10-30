<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="KioskLogs.ascx.cs" Inherits="BNet.Cafe.Server.Forms.KioskLogs" %>
<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:LinkButton ID="LinkButton_Refresh" runat="server"></asp:LinkButton>
        <div class="cards-grid cards-grid-compact">
            <!-- Total Logs Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-list-check"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Logs</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalLogs" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="positive-sm">Overall</span>
            </div>

            <!-- Successful Transactions Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-circle-check"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Successful</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_SuccessfulLogs" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status green">Completed</span>
            </div>

            <!-- Failed Transactions Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-circle-xmark"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Failed</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_FailedLogs" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status red">Unsuccessful</span>
            </div>

            <!-- Total Amount Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-money-bill-wave"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Amount</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalAmount" runat="server" Text="0.00"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status yellow">Processed</span>
            </div>
        </div>

        <div class="bnet-table-wrapper">
            <div class="bnet-table-toolbar">
                <div class="search-box">
                    <asp:TextBox ID="TextBox_Search" runat="server" CssClass="search-input" AutoPostBack="True" OnTextChanged="TextBox_Search_TextChanged" placeholder="Search details or reference no..." />
                </div>
                <asp:TextBox ID="TextBox_DateRage" AutoPostBack="true" CssClass="bnet-datepicker" data-mode="range" runat="server"></asp:TextBox>
            </div>

            <div class="bnet-table-container">
                <asp:GridView ID="GridViewTable" runat="server" ShowHeaderWhenEmpty="true"
                    AutoGenerateColumns="False" CssClass="bnet-table" GridLines="None"
                    AllowPaging="True" OnPageIndexChanging="GridViewTable_PageIndexChanging">

                    <PagerSettings Mode="NumericFirstLast" FirstPageText="&laquo;" LastPageText="&raquo;" PreviousPageText="&lsaquo;" NextPageText="&rsaquo;" PageButtonCount="5" />
                    <PagerStyle CssClass="bnet-pagination" HorizontalAlign="Center" />

                    <Columns>
                        <asp:TemplateField HeaderText="Id" ItemStyle-Width="100px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBId" runat="server" Text='<%# Eval("DBId") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Type" ItemStyle-Width="180px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBType" runat="server" Text='<%# Eval("DBType") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Details" ItemStyle-Width="200px">
                            <ItemTemplate>
                                <asp:Panel ID="Panel_Details" runat="server" CssClass='<%# Eval("DBDetails") != null && Eval("DBDetails").ToString().Contains("EXTENSION") ? "bnet-badge-status blue" : (Eval("DBDetails") != null && Eval("DBDetails").ToString().Contains("CREATION") ? "bnet-badge-status green" : "") %>'>
                                    <asp:Label ID="Label_DBDetails" runat="server" Text='<%# Eval("DBDetails") %>'></asp:Label>
                                </asp:Panel>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:TemplateField HeaderText="Amount" ItemStyle-Width="140px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBAmount" runat="server" Text='<%# Eval("DBAmount") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Status" ItemStyle-Width="130px">
                            <ItemTemplate>
                                <asp:Panel ID="Panel_Status" runat="server" CssClass='<%# Convert.ToBoolean(Eval("DBIsSuccess")) ? "bnet-badge-status green" : "bnet-badge-status red" %>'>
                                    <%# Convert.ToBoolean(Eval("DBIsSuccess")) ? "Success" : "Failed" %>
                                </asp:Panel>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Date & Time" ItemStyle-Width="220px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBDateCreated_DBTimeCreated" runat="server" Text='<%# string.Format("{0} - {1}", Eval("DBDateCreated"), Eval("DBTimeCreated")) %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </div>
            <asp:Panel ID="Panel_Pagination" runat="server" />
        </div>
    </ContentTemplate>
</asp:UpdatePanel>
