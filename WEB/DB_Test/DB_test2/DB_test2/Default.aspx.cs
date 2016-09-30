using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Web.Configuration;
using System.Windows;

namespace DB_test2
{
    public partial class WebForm1 : System.Web.UI.Page
    {
        private int raekkeIndeks = -1;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!this.IsPostBack)
            {
                FillGridView();
            }
        }

        /// Fill record into GridView
        /// </summary>
        public void FillGridView()
        {
            try
            {
                string connectionString = WebConfigurationManager.ConnectionStrings["dbConnectionString"].ConnectionString;
                string selectSQL = "SELECT * from tblBruger";
                SqlConnection con = new SqlConnection(connectionString);
                SqlCommand cmd = new SqlCommand(selectSQL, con);
                SqlDataAdapter adapter = new SqlDataAdapter(cmd);
                DataSet ds = new DataSet();

                adapter.Fill(ds, "tblBruger");

                GridView1.DataSource = ds;
                GridView1.DataBind();
            }
            catch
            {
                Response.Write("<script> alert('Connection String Error...') </script>");
            }
        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {
            //ScriptManager.RegisterStartupScript(this, this.GetType(), "myconfirm", "OpenConfirmDialog();", true);
            GridView1.EditIndex = e.NewEditIndex;
            raekkeIndeks = e.NewEditIndex;
            //Bind data to the GridView control.
            FillGridView();
       //     foreach (GridViewRow row in GridView1.Rows)
       //     {
       //         TextBox chkVal = ((TextBox)row.FindControl("TextBox1"));
       //         if (1==1)
       //         {
       //             chkVal.ReadOnly = false;
       //         }
			    //{
       //             chkVal.ReadOnly = true;
       //         }
       //     }
        }

        public void Button1_Click()
        {
            ClientScriptManager CSM = Page.ClientScript;
            if (!ReturnValue())
            {
                string strconfirm = "<script>if(!window.confirm('Are you sure?')){window.location.href='Default.aspx'}</script>";
                CSM.RegisterClientScriptBlock(this.GetType(), "Confirm", strconfirm, false);
            }
        }
        bool ReturnValue()
        {
            return false;
        }

        protected void GridView1_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
        {
            FillGridView();
            //confirm("Press a button!");
        }

        protected void Button1_Click1(object sender, EventArgs e)
        {
            //int rowIndex = GridView1.SelectedRow.RowIndex;
            GridView1.EditIndex = 0;
            //GridView1.Columns.Clear();
            //GridView1.SetEditRow(index);
            FillGridView();
        }

        protected void GridView1_SelectedIndexChanged(object sender, EventArgs e)
        {
            int index = raekkeIndeks;
            //string name = GridView1.SelectedRow.Cells[0].Text;
            //string country = GridView1.SelectedRow.Cells[1].Text;
            //string message = "Row Index: " + index + "\\nName: " + name + "\\nCountry: " + country;
            //ClientScript.RegisterStartupScript(this.GetType(), "alert", "alert('" + message + "');", true);
        }

        protected void OnRowDataBound(object sender, System.Web.UI.WebControls.GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                //if (!tableco)
                //e.Row.Attributes.Add("onclick", ClientScript.GetPostBackEventReference(GridView1, "Select$" + e.Row.RowIndex.ToString()));
                e.Row.Attributes["onclick"] = ClientScript.GetPostBackClientHyperlink(GridView1, "Edit$" + e.Row.DataItemIndex, true);
                //GridView1.Rows[GridView1.EditIndex].Cells[2].Controls[0].Focus();
                TextBox txtBox = (TextBox)GridView1. Rows[0].Cells[1].Controls[0].cl;

                txtBox.Attributes.Add("onkeypress", "return abc();");

            }
        }
    }
}