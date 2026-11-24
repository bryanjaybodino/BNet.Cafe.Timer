<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Transactions.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Transactions" %>
<%@ Register Src="~/Forms/Modals/TransactionReset.ascx" TagPrefix="uc" TagName="TransactionReset" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server">
    <ContentTemplate>
        <div class="bnet-table-wrapper">
            <div class="content-header" style="margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
                <div>
                    <h1 style="font-size: 20px; display: flex; align-items: center; gap: 8px;">
                        Transaction Management
                    </h1>
                    <p>Manage current and previous collections</p>
                </div>
                <div>
                    <asp:TextBox ID="TextBox_DateRage" AutoPostBack="true" CssClass="bnet-datepicker" data-mode="range" runat="server" OnTextChanged="TextBox_DateRage_TextChanged"></asp:TextBox>
                </div>
            </div>

            <div class="card" style="display: flex; flex-direction: column; gap: 20px; box-shadow: 0 4px 16px rgba(0,0,0,0.04);">

                <!-- Top Up Row -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; border-radius: 8px; border-bottom: 1px solid var(--border-light); background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 15px; font-weight: 600; color: var(--text-light); margin-bottom: 2px;">Top Up</h3>
                        <span style="font-size: 12px; color: var(--text-light-secondary);">Current collection</span>
                    </div>
                    <div style="text-align: right; display: flex; align-items: center; gap: 16px;">
                        <span style="font-size: 18px; font-weight: 700; color: var(--text-light);">
                            <asp:Label ID="Label_TopUpCollection" runat="server" Text="₱0.00"></asp:Label>
                        </span>
                    </div>
                </div>

                <!-- Rental Row -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; border-radius: 8px; border-bottom: 1px solid var(--border-light); background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 15px; font-weight: 600; color: var(--text-light); margin-bottom: 2px;">Rental</h3>
                        <span style="font-size: 12px; color: var(--text-light-secondary);">Current collection</span>
                    </div>
                    <div style="text-align: right; display: flex; align-items: center; gap: 16px;">
                        <span style="font-size: 18px; font-weight: 700; color: var(--text-light);">
                            <asp:Label ID="Label_RentalCollection" runat="server" Text="₱0.00"></asp:Label>
                        </span>
                    </div>
                </div>

                <!-- Sales Row -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; border-radius: 8px; border-bottom: 1px solid var(--border-light); background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 15px; font-weight: 600; color: var(--text-light); margin-bottom: 2px;">Sales</h3>
                        <span style="font-size: 12px; color: var(--text-light-secondary);">Current collection</span>
                    </div>
                    <div style="text-align: right; display: flex; align-items: center; gap: 16px;">                    
                        <span style="font-size: 18px; font-weight: 700; color: var(--text-light);">
                            <asp:Label ID="Label_SalesCollection" runat="server" Text="₱0.00"></asp:Label>
                        </span>
                    </div>
                </div>

                <!-- Voucher Row -->
                <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; border-radius: 8px; border-bottom: 1px solid var(--border-light); background-color: var(--bg-light-tertiary);">
                    <div>
                        <h3 style="font-size: 15px; font-weight: 600; color: var(--text-light); margin-bottom: 2px;">Voucher</h3>
                        <span style="font-size: 12px; color: var(--text-light-secondary);">Current collection</span>
                    </div>
                    <div style="text-align: right; display: flex; align-items: center; gap: 16px;">
                        <span style="font-size: 18px; font-weight: 700; color: var(--text-light);">
                            <asp:Label ID="Label_VoucherCollection" runat="server" Text="₱0.00"></asp:Label>
                        </span>
                    </div>
                </div>

                <!-- Collection Period Section -->
                <div style="padding: 4px 8px;">
                    <h3 style="font-size: 14px; font-weight: 600; color: var(--text-light-secondary); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px;">Collection Period</h3>
                    <div style="font-size: 15px; font-weight: 600; color: var(--text-light);">
                        <asp:Label ID="Label_CollectionPeriod" runat="server" Text="--"></asp:Label>
                    </div>
                </div>

                <!-- Reset Button Action -->
                <div class="form-grid-action" style="margin-top: 4px; border-top: 1px solid var(--border-light); padding-top: 16px;">
                    <button type="button" class="btn btn-danger" style="width: 100%; justify-content: center; padding: 12px;" onclick="openResetModal()">
                        <i class="fa-solid fa-rotate-right" style="margin-right: 6px;"></i> Reset Collection
                    </button>
                </div>

            </div>
        </div>

        <uc:TransactionReset runat="server" ID="TransactionResetModal" />
    </ContentTemplate>
</asp:UpdatePanel>