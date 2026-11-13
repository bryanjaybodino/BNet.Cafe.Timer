<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="PricingRequiredModal.ascx.cs" Inherits="BNet.Cafe.Server.Forms.Modals.PricingRequiredModal" %>

<div id="pricingRequiredModal" class="bnet-modal-overlay">
    <div class="bnet-modal-container">
        <div class="bnet-modal-header">
            <h3 class="bnet-modal-title">
                <i class="fa-solid fa-triangle-exclamation" style="color: #f39c12; margin-right: 8px;"></i> Pricing Setting Required
            </h3>
            <span class="bnet-modal-close" onclick="closePricingRequiredModal()">&times;</span>
        </div>
        <div class="bnet-modal-body">
            <p><strong>You cannot open the kiosk because no pricing setting has been configured yet.</strong></p>
            <p style="margin-top: 10px; color: var(--text-light-secondary); font-size: 13px;">Please add at least one pricing rule below before proceeding.</p>
        </div>
        <div class="bnet-modal-footer">
            <span class="btn btn-primary" onclick="closePricingRequiredModal()">Got it</span>
        </div>
    </div>
</div>

<script type="text/javascript">
    let pricingRequiredModalInstance = null;

    function getPricingRequiredModal() {
        if (!pricingRequiredModalInstance) {
            pricingRequiredModalInstance = new BNetModal('#pricingRequiredModal');
        }
        return pricingRequiredModalInstance;
    }

    function openPricingRequiredModal() {
        setTimeout(function () {
            getPricingRequiredModal().open();
        }, 150);
    }

    function closePricingRequiredModal() {
        getPricingRequiredModal().close();
    }

    // Automatically check URL parameters and rule count on page load / update panel refresh
    function checkAndShowRequiredModal() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('Required')) {
            openPricingRequiredModal();
        }
    }

    // Run on initial load
    document.addEventListener("DOMContentLoaded", function () {
        checkAndShowRequiredModal();
    });

    // Run after ASP.NET AJAX UpdatePanel postbacks
    if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () {
            pricingRequiredModalInstance = new BNetModal('#pricingRequiredModal');
            checkAndShowRequiredModal();
        });
    }
</script>