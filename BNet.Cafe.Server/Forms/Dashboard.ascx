<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Dashboard.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Dashboard" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <asp:LinkButton ID="LinkButton_Refresh" runat="server"></asp:LinkButton>
        <asp:HiddenField ID="HiddenField_ChartData" runat="server" />

        <div class="bnet-table-toolbar dashboard-toolbar">
            <h2 class="dashboard-heading">Dashboard</h2>
            <asp:TextBox ID="TextBox_DateRage" AutoPostBack="true" CssClass="bnet-datepicker" data-mode="range"
                runat="server"></asp:TextBox>
        </div>

        <!-- KPI Cards Grid - Row 1 -->
        <div class="cards-grid cards-grid-compact">
            <!-- Transactions -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-receipt"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Transactions</span>
                        <b>
                            <asp:Label ID="Label_TotalTransactions" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status blue">Overall</span>
            </div>

            <!-- Users -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-users"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Users</span>
                        <b>
                            <asp:Label ID="Label_Users" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status green">Members</span>
            </div>

            <!-- Walk-In -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-user-clock"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Walk In</span>
                        <b>
                            <asp:Label ID="Label_WalkIn" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status gray">Guests</span>
            </div>

            <!-- Rental Income -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-desktop"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Rental Income</span>
                        <b>
                            <asp:Label ID="Label_Income" runat="server" Text="₱0.00"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status yellow">Rentals</span>
            </div>

            <!-- Top-Up Load -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-wallet"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Top-Up Load</span>
                        <b>
                            <asp:Label ID="Label_TopUpIncome" runat="server" Text="₱0.00"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status green">Credits</span>
            </div>
        </div>

        <!-- KPI Cards Grid - Row 2 -->
        <div class="cards-grid cards-grid-compact">
            <!-- Product Sales Revenue -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-cart-shopping"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Sales Revenue</span>
                        <b>
                            <asp:Label ID="Label_SalesRevenue" runat="server" Text="₱0.00"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status green">Sales</span>
            </div>

            <!-- Total Restock Costs -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-coins"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Restock Costs</span>
                        <b>
                            <asp:Label ID="Label_TotalCosts" runat="server" Text="₱0.00"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status red">Stock In Cost</span>
            </div>

            <!-- Inventory Summary -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-boxes-stacked"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Inventory Items</span>
                        <b>
                            <asp:Label ID="Label_TotalInventory" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status gray">Low:
                    <asp:Label ID="Label_LowStockCount" runat="server" Text="0"></asp:Label>
                </span>
            </div>

            <!-- Active Suppliers -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-truck-field"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Suppliers</span>
                        <b>
                            <asp:Label ID="Label_TotalSuppliers" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status blue">Active</span>
            </div>

            <!-- Total Games (Game Menu) -->
            <div class="card card-compact">
                <div class="card-inline-content">
                    <div class="card-icon-sm">
                        <i class="fa-solid fa-gamepad"></i>
                    </div>
                    <div class="card-details">
                        <span class="card-title-sm">Total Games</span>
                        <b>
                            <asp:Label ID="Label_DashboardGameMenus" runat="server" Text="0"></asp:Label></b>
                    </div>
                </div>
                <span class="bnet-badge-status yellow">Game Menu</span>
            </div>
        </div>

        <!-- Charts Row 1: Revenue trend + Customer types -->
        <div class="charts-grid">
            <div class="card-chart span-2">
                <div class="chart-header">
                    <span class="chart-title">Revenue Trend</span>
                </div>
                <div class="chart-container" id="ChartContainerLine">
                    <svg id="DashboardLineChart" viewBox="0 0 600 240"></svg>
                </div>
            </div>

            <div class="card-chart">
                <div class="chart-header">
                    <span class="chart-title">Customer Types</span>
                </div>
                <div class="chart-container" id="ChartContainerDonut">
                    <svg id="DashboardDonutChart" viewBox="0 0 200 200"></svg>
                </div>
                <div class="legend-container" id="DashboardDonutLegend">
                    <div class="legend-item">
                        <div class="legend-color" style="background: var(--accent-green, #10b981);"></div>
                        Members: <span id="LegendMembersValue">0</span>
                    </div>
                    <div class="legend-item">
                        <div class="legend-color" style="background: var(--primary, #3b82f6);"></div>
                        Walk-In: <span id="LegendWalkInValue">0</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Charts Row 2: Sales vs Restock Cost Trend -->
        <div class="charts-grid">
            <div class="card-chart span-3">
                <div class="chart-header">
                    <span class="chart-title">Sales vs. Restock Cost Overview</span>
                    <div class="legend-container" style="margin-top: 0;">
                        <div class="legend-item">
                            <div class="legend-color" style="background: #10b981;"></div>
                            Sales Revenue
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background: #ef4444;"></div>
                            Restock Cost
                        </div>
                    </div>
                </div>
                <div class="chart-container" id="ChartContainerSalesVsCost">
                    <svg id="DashboardSalesVsCostChart" viewBox="0 0 900 240"></svg>
                </div>
            </div>
        </div>

        <!-- Charts Row 3: Computer usage -->
        <div class="charts-grid">
            <div class="card-chart span-3">
                <div class="chart-header">
                    <span class="chart-title">Computer Usage (Transactions per Terminal)</span>
                </div>
                <div class="chart-container" id="ChartContainerBar">
                    <svg id="DashboardBarChart" viewBox="0 0 800 240"></svg>
                </div>
            </div>
        </div>

        <!-- Charts Row 4: Peak Hours / Hourly Activity Bar Chart -->
        <div class="charts-grid">
            <div class="card-chart span-3">
                <div class="chart-header">
                    <span class="chart-title">Peak Player Hours & Activity (Transactions by Hour of Day)</span>
                </div>
                <div class="chart-container" id="ChartContainerHourlyBar">
                    <svg id="DashboardHourlyBarChart" viewBox="0 0 800 240"></svg>
                </div>
            </div>
        </div>

        <!-- Leaderboards Row: Top Member Spenders & Top Games -->
        <div class="charts-grid">
            <!-- Top 10 Member Spenders Leaderboard -->
            <div class="card-chart">
                <div class="chart-header">
                    <span class="chart-title">Top 10 Member Top-Up Spenders</span>
                </div>
                <div class="bnet-table-container">
                    <table class="bnet-table" id="TableTopUsers">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Member</th>
                                <th>Count</th>
                                <th>Amount</th>
                            </tr>
                        </thead>
                        <tbody id="TableTopUsersBody">
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Top 10 Games Leaderboard -->
            <div class="card-chart span-2">
                <div class="chart-header">
                    <span class="chart-title">Top 10 Popular Games</span>
                </div>
                <div class="bnet-table-container">
                    <table class="bnet-table" id="TableTopGames">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Game Name</th>
                                <th>Category</th>
                                <th>Total Count</th>
                            </tr>
                        </thead>
                        <tbody id="TableTopGamesBody">
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>