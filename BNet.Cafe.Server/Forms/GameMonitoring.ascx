<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="GameMonitoring.ascx.cs" Inherits="BNet.Cafe.Server.Forms.GameMonitoring" %>
<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:LinkButton ID="LinkButton_Refresh" runat="server"></asp:LinkButton>
        <div class="cards-grid cards-grid-compact">
            <!-- Total Games Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-gamepad"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Games</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalGames" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="positive-sm">Overall</span>
            </div>

            <!-- Total Categories Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-list"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Categories</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalCategories" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status green">Active</span>
            </div>

            <!-- Total Computers Card -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-computer"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Computers</span>
                        <span class="card-value-sm">
                            <asp:Label ID="Label_TotalComputers" runat="server" Text="0"></asp:Label>
                        </span>
                    </div>
                </div>
                <span class="bnet-badge-status yellow">Assigned</span>
            </div>
        </div>

        <div class="bnet-table-wrapper">
            <div class="bnet-table-toolbar">
                <div class="search-box">
                    <asp:TextBox ID="TextBox_Search" runat="server" CssClass="search-input" AutoPostBack="True" OnTextChanged="TextBox_Search_TextChanged" placeholder="Search app name, category, or computer..." />
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
                        <asp:TemplateField HeaderText="Id" ItemStyle-Width="120px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBId" runat="server" Text='<%# Eval("DBId") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="App Name" ItemStyle-Width="200px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBAppName" runat="server" Text='<%# Eval("DBAppName").ToString().Replace(".LNK","") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Category" ItemStyle-Width="180px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBCategory" runat="server" Text='<%# Eval("DBCategory") %>'></asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Computer Name" ItemStyle-Width="180px">
                            <ItemTemplate>
                                <asp:Label ID="Label_DBComputerName" runat="server" Text='<%# Eval("DBComputerName") %>'></asp:Label>
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