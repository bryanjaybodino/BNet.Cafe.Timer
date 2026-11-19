<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="POS.ascx.cs" Inherits="BNet.Cafe.Server.Forms.POS" %>
<%@ Register Src="~/Forms/Modals/POSReceipt.ascx" TagPrefix="uc1" TagName="POSReceipt" %>

<asp:UpdatePanel ID="UpdatePanel1" runat="server" UpdateMode="Conditional" ChildrenAsTriggers="true">
    <ContentTemplate>
        <div class="pos-container">

            <!-- ============ Catalog ============ -->
            <section class="pos-catalog-panel" aria-label="Product catalog">
                <div class="pos-toolbar">
                    <div class="pos-filter-group">
                        <div class="pos-search-box">
                            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
                            <asp:TextBox ID="TextBox_Search" runat="server" CssClass="search-input"
                                Placeholder="Search products" AutoPostBack="true"
                                OnTextChanged="Filter_Changed"
                                onkeydown="if(event.keyCode===13){this.blur(); return false;}" />
                        </div>

                        <div class="pos-select-box">
                            <i class="fa-solid fa-layer-group select-icon" aria-hidden="true"></i>
                            <asp:DropDownList ID="DropDownList_Category" runat="server" CssClass="category-select"
                                AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed">
                            </asp:DropDownList>
                        </div>
                    </div>
                </div>

                <div class="product-grid">
                    <asp:Repeater ID="Repeater_Products" runat="server" OnItemCommand="Repeater_Products_ItemCommand">
                        <ItemTemplate>
                            <asp:LinkButton ID="btnSelectProduct" runat="server" CommandName="AddToCart" CommandArgument='<%# Eval("DBId") %>' CssClass="pos-card-link">
                                <div class='<%# Convert.ToInt32(Eval("DBQuantityInStock")) <= 0 ? "pos-product-card is-out" : "pos-product-card" %>'>
                                    <div class="product-img-wrapper">
                                        <img src='<%# GetProductImage(Eval("DBId")) %>' alt='<%# Eval("DBItemName") %>' loading="lazy" decoding="async" />
                                        <div class='<%# Convert.ToInt32(Eval("DBQuantityInStock")) <= 0 ? "stock-badge out-of-stock" : (Convert.ToInt32(Eval("DBQuantityInStock")) <= 5 ? "stock-badge low-stock" : "stock-badge in-stock") %>'>
                                            <%# Convert.ToInt32(Eval("DBQuantityInStock")) <= 0 ? "Out of stock" : Eval("DBQuantityInStock") + " left" %>
                                        </div>
                                    </div>
                                    <div class="product-info">
                                        <div class="product-name" title='<%# Eval("DBItemName") %>'><%# Eval("DBItemName") %></div>
                                        <div class="product-category"><%# Eval("DBCategory") %></div>
                                        <div class="product-price-row">
                                            <span class="product-price">₱<%# Convert.ToDouble(Eval("DBUnitPrice")).ToString("N2") %></span>
                                            <span class="add-btn-icon" aria-hidden="true"><i class="fa-solid fa-plus"></i></span>
                                        </div>
                                    </div>
                                </div>
                            </asp:LinkButton>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="Panel_NoResults" runat="server" Visible="false" CssClass="pos-no-results">
                        <span class="pos-empty-icon"><i class="fa-solid fa-magnifying-glass"></i></span>
                        <div class="pos-empty-title">No products found</div>
                        <div class="pos-empty-text">Clear the search or pick a different category.</div>
                    </asp:Panel>
                </div>
            </section>

            <!-- ============ Order / Checkout ============ -->
            <aside class="pos-checkout-panel" aria-label="Current order">

                <div class="pos-cart-head">
                    <div class="pos-cart-title">
                        <i class="fa-solid fa-receipt" aria-hidden="true"></i>
                        <span>Current order</span>
                        <span class="pos-cart-count is-empty" aria-live="polite">No items</span>
                    </div>
                    <button type="button" class="pos-sheet-toggle" aria-expanded="false" aria-label="Show or hide order details" onclick="return togglePOSCart();">
                        <i class="fa-solid fa-chevron-up" aria-hidden="true"></i>
                    </button>
                </div>

                <div class="cart-table-wrapper">
                    <asp:GridView ID="GridView_Cart" runat="server" AutoGenerateColumns="False"
                        CssClass="cart-table" OnRowCommand="GridView_Cart_RowCommand" GridLines="None">
                        <HeaderStyle CssClass="cart-head" />
                        <RowStyle CssClass="cart-row" />
                        <Columns>
                            <asp:TemplateField HeaderText="Item" ItemStyle-CssClass="cell-name">
                                <ItemTemplate>
                                    <div class="cart-item-name"><%# HttpUtility.HtmlEncode(Convert.ToString(Eval("ItemName"))) %></div>
                                    <div class="cart-item-unit">₱<%# Convert.ToDouble(Eval("UnitPrice")).ToString("N2") %> each</div>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Qty" ItemStyle-CssClass="cell-qty">
                                <ItemTemplate>
                                    <div class="qty-controls">
                                        <asp:LinkButton ID="btnDecrease" runat="server" CommandName="DecreaseQty" CommandArgument='<%# Eval("ItemId") %>' CssClass="qty-btn" ToolTip="Decrease quantity" aria-label="Decrease quantity"><i class="fa-solid fa-minus"></i></asp:LinkButton>
                                        <span class="qty-value"><%# Eval("Quantity") %></span>
                                        <asp:LinkButton ID="btnIncrease" runat="server" CommandName="IncreaseQty" CommandArgument='<%# Eval("ItemId") %>' CssClass="qty-btn" ToolTip="Increase quantity" aria-label="Increase quantity"><i class="fa-solid fa-plus"></i></asp:LinkButton>
                                    </div>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="Subtotal" ItemStyle-CssClass="cell-sub">
                                <ItemTemplate>
                                    <span class="cart-item-sub">₱<%# Convert.ToDouble(Eval("Subtotal")).ToString("N2") %></span>
                                </ItemTemplate>
                            </asp:TemplateField>

                            <asp:TemplateField HeaderText="" ItemStyle-CssClass="cell-remove">
                                <ItemTemplate>
                                    <asp:LinkButton ID="btnRemove" runat="server" CommandName="RemoveItem" CommandArgument='<%# Eval("ItemId") %>' CssClass="cart-remove" ToolTip="Remove item" aria-label="Remove item">
                                        <i class="fa-regular fa-trash-can"></i>
                                    </asp:LinkButton>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate>
                            <div class="pos-empty">
                                <span class="pos-empty-icon"><i class="fa-solid fa-basket-shopping"></i></span>
                                <div class="pos-empty-title">Order is empty</div>
                                <div class="pos-empty-text">Tap a product to add it here.</div>
                            </div>
                        </EmptyDataTemplate>
                    </asp:GridView>
                </div>

                <div class="cart-summary">

                    <div class="pos-session">
                        <div class="pos-field">
                            <asp:Label runat="server" AssociatedControlID="DropDownList_POSComputer" CssClass="pos-field-label" Text="PC terminal" />
                            <asp:DropDownList ID="DropDownList_POSComputer" runat="server" CssClass="form-control bnet-select pos-select" AutoPostBack="true" OnSelectedIndexChanged="DropDownList_POSComputer_SelectedIndexChanged">
                            </asp:DropDownList>
                        </div>
                        <div class="pos-field">
                            <asp:Label runat="server" AssociatedControlID="DropDownList_POSCustomer" CssClass="pos-field-label" Text="Customer" />
                            <asp:DropDownList ID="DropDownList_POSCustomer" runat="server" CssClass="form-control bnet-select pos-select" AutoPostBack="true" OnSelectedIndexChanged="DropDownList_POSCustomer_SelectedIndexChanged">
                            </asp:DropDownList>
                        </div>
                    </div>

                    <asp:Panel ID="Panel_Points" runat="server" Visible="false" CssClass="pos-points">
                        <div class="pos-points-balance">
                            <i class="fa-solid fa-coins" aria-hidden="true"></i>
                            <span>Points</span>
                            <strong>
                                <asp:Literal ID="litAvailablePoints" runat="server">0</asp:Literal></strong>
                        </div>
                        <div>
                            <label class="bnet-toggle-wrapper">
                                <asp:CheckBox ID="CheckBox_UsePoints" runat="server" AutoPostBack="true" OnCheckedChanged="CheckBox_UsePoints_CheckedChanged" />
                                <span class="bnet-toggle-slider"></span>
                                <span>Use points</span>
                            </label>
                        </div>
                    </asp:Panel>

                    <div class="total-row">
                        <span class="total-label">Total payable</span>
                        <span class="total-amount"><span class="pos-currency">₱</span><asp:Label ID="Label_Total" runat="server" Text="0.00"></asp:Label></span>
                    </div>

                    <div class="cart-actions">
                        <asp:LinkButton ID="LinkButton_Clear" OnClick="LinkButton_Clear_Click" CssClass="btn btn-secondary pos-btn pos-btn-ghost" runat="server">
                            <i class="fa-solid fa-rotate-left" aria-hidden="true"></i> Clear
                        </asp:LinkButton>
                        <asp:LinkButton ID="LinkButton_Submit" OnClick="LinkButton_Submit_Click" CssClass="btn btn-primary pos-btn pos-btn-primary" OnClientClick="return ValidatePOSCart();" runat="server">
                            <i class="fa-solid fa-check" aria-hidden="true"></i> Complete sale
                        </asp:LinkButton>
                    </div>
                </div>
            </aside>
        </div>
        <uc1:POSReceipt runat="server" ID="POSReceipt" />
    </ContentTemplate>
</asp:UpdatePanel>
