<%@ Page Title="" Language="C#" MasterPageFile="~/Main.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="DB_test2.WebForm1" EnableEventValidation = "false" %>
<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="ContentPlaceHolder1" runat="server">
    Henrik Due Jensen<asp:GridView ID="GridView1" runat="server" OnRowEditing="GridView1_RowEditing" 
        OnRowCancelingEdit="GridView1_RowCancelingEdit" OnSelectedIndexChanged="GridView1_SelectedIndexChanged" 
        OnRowDataBound="OnRowDataBound" OnUnload="GridView1_SelectedIndexChanged" >
        <Columns>
            <asp:CommandField ShowEditButton="True" />
        </Columns>
</asp:GridView>
<asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:DBTestConnectionString %>" SelectCommand="SELECT [ID], [Fornavn], [Efternavn], [By] FROM [tblBruger]"></asp:SqlDataSource>
    <asp:Button ID="Button1" runat="server" OnClick="Button1_Click1" Text="Button" />
    <p id="demo"></p>
&nbsp;
    <script type = "text/javascript">
        function Confirm() {
            var confirm_value = document.createElement("INPUT");
            confirm_value.type = "hidden";
            confirm_value.name = "confirm_value";
            if (confirm("Do you want to save data?")) {
                confirm_value.value = "Yes";
            } else {
                confirm_value.value = "No";
            }
            document.forms[0].appendChild(confirm_value);
        }
        function abc()
    {
        var a=20;
        var b=30;
        alert("you enter"+a+":"+b);
    }
    </script>
    </script>
</asp:Content>
