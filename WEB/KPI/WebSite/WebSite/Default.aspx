<%@ Page Title="" Language="C#" MasterPageFile="~/Main.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebSite.Default" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    <div>
        <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" OnRowCancelingEdit="GridView1_RowCancelingEdit" OnRowEditing="GridView1_RowEditing" OnRowUpdating="GridView1_RowUpdating">
        <Columns>
            <%--<asp:BoundField DataField="ID"  HeaderText="TabelID" Visible="false"/>--%>
            <asp:BoundField DataField="KPI_Navn"  HeaderText="KPI_Navn"/>
            <asp:BoundField DataField="vaerdi_jan" HeaderText="Januar"/>
            <asp:BoundField DataField="vaerdi_feb" HeaderText="Februar"/>
            <%--<asp:BoundField DataField="Værdi" HeaderText="Værdi"/>--%>
            <asp:CommandField ShowEditButton="True" />
        </Columns>
        </asp:GridView>    
    </div>
</asp:Content>
