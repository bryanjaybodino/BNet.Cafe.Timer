<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Print.aspx.cs" Async="true" AsyncTimeout="999999999" Inherits="BNet.Cafe.Server.Print" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" ScriptMode="Release"></asp:ScriptManager>
        <rsweb:ReportViewer ID="ReportViewer1" runat="server" Width="100%" Height="0" ZoomMode="Percent"></rsweb:ReportViewer>
        <asp:HiddenField ID="HiddenField1" runat="server" />
    </form>
</body>
</html>
