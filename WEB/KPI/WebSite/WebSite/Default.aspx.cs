using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;

namespace WebSite
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                BindGridView();
            }
        }

        #region Connection
        private string GetConnectionString()
        {
            return ConfigurationManager.ConnectionStrings["MDW_test07ConnectionString"].ConnectionString;
        }
        #endregion

        #region Bind GridView
        private void BindGridView()
        {

            DataTable dt = new DataTable();
            SqlConnection connection = new SqlConnection(GetConnectionString());

            try
            {
                connection.Open();
                #region sqlstatement
                string sqlStatement = "select * from " +
                "( " +
                "select der_jan.Opslag,der_jan.Tavle,der_jan.KPI_Navn,der_jan.Ansvarlig,der_jan.Filnavn,der_jan.Tidsberegning,der_jan.Element,der_jan.vaerdi_jan,der_feb.vaerdi_feb from  " +
                "( " +
                "SELECT a.[Opslag],a.[Tavle],a.[KPI_ID],a.[KPI_Navn],a.[Ansvarlig],a.[Filnavn],b.Tidsberegning,b.Element,b.Værdi vaerdi_jan " +
                "FROM [ods].[MD_KPI_Tavlestyring] a " +
                "join [ods].[MD_KPI_Export_Data] b on a.KPI_ID=b.KPI_ID " +
                "where a.Ansvarlig='Morten Nyhave' and b.Periode=('01-01-2015')	and b.Element='Måltal' and b.Tidsberegning='Periode' " +
                ") der_jan " +
                "join " +
                "( " +
                "SELECT a.[Opslag],a.[Tavle],a.[KPI_ID],a.[KPI_Navn],a.[Ansvarlig],a.[Filnavn],b.Tidsberegning,b.Element,b.Værdi vaerdi_feb " +
                "FROM [ods].[MD_KPI_Tavlestyring] a " +
                "join [ods].[MD_KPI_Export_Data] b on a.KPI_ID=b.KPI_ID " +
                "where a.Ansvarlig='Morten Nyhave' and b.Periode in ('01-02-2015') and b.Element='Måltal' and b.Tidsberegning='Periode' " +
                ") der_feb on der_jan.KPI_ID=der_feb.KPI_ID " +
                ") der_alle ";
                #endregion



                //string sqlStatement = "SELECT top 10 ID,[Periode],[Tidsberegning],[Element],[Værdi] " +
                //    "FROM [MDW_test07].[ods].[MD_KPI_Export_Data] order by ID desc";
                SqlCommand sqlCmd = new SqlCommand(sqlStatement, connection);
                SqlDataAdapter sqlDa = new SqlDataAdapter(sqlCmd);
                sqlDa.Fill(dt);

                if (dt.Rows.Count > 0)
                {
                    GridView1.DataSource = dt;
                    GridView1.DataBind();
                }
            }
            catch (System.Data.SqlClient.SqlException ex)
            {
                string msg = "Fetch Error:";
                msg += ex.Message;
                throw new Exception(msg);
            }
            finally
            {
                connection.Close();
            }
        }
        #endregion


        #region Insert New or Update Record
        private void UpdateOrAddNewRecord(string Id, string Periode, string Tidsberegning, string Element, string Værdi, bool isUpdate)
        {
            SqlConnection connection = new SqlConnection(GetConnectionString());
            string sqlStatement = string.Empty;

            if (!isUpdate)
            {
                sqlStatement = "INSERT INTO ods.MD_KPI_Export_Data " +
                                "(Periode,Tidsberegning,Element,Værdi)" +
                               "VALUES " +
                                "(@Periode,@Tidsberegning,@Element,@Værdi)";
            }
            else
            {
                sqlStatement = "UPDATE ods.MD_KPI_Export_Data " +
                               "SET Periode = @Periode, Tidsberegning = @Tidsberegning," +
                               "Element = @Element,Værdi = @Værdi " +
                               "WHERE ID = @Id";
            }
            try
            {
                connection.Open();
                SqlCommand cmd = new SqlCommand(sqlStatement, connection);
                cmd.Parameters.AddWithValue("@Periode", Periode);
                cmd.Parameters.AddWithValue("@Tidsberegning", Tidsberegning);
                cmd.Parameters.AddWithValue("@Element", Element);
                cmd.Parameters.AddWithValue("@Værdi", Værdi);
                cmd.Parameters.AddWithValue("@Id", Id);
                cmd.CommandType = CommandType.Text;
                cmd.ExecuteNonQuery();
            }
            catch (System.Data.SqlClient.SqlException ex)
            {
                string msg = "Insert/Update Error:";
                msg += ex.Message;
                throw new Exception(msg);

            }
            finally
            {
                connection.Close();
            }
        }
        #endregion

        protected void GridView1_RowCancelingEdit(object sender, GridViewCancelEditEventArgs e)
        {
            GridView1.EditIndex = -1; //swicth back to default mode
            BindGridView(); // Rebind GridView to show the data in default mode
        }

        protected void GridView1_RowEditing(object sender, GridViewEditEventArgs e)
        {
            GridView1.EditIndex = e.NewEditIndex; // turn to edit mode
            BindGridView(); // Rebind GridView to show the data in edit mode
        }

        protected void GridView1_RowUpdating(object sender, GridViewUpdateEventArgs e)
        {
            //Accessing Edited values from the GridView
            int rowIndex = Convert.ToInt32(e.RowIndex);
            string ID = ((TextBox)GridView1.Rows[e.RowIndex].Cells[0].Controls[0]).Text;
            string strID = GridView1.DataKeys[rowIndex].Value.ToString();
            //strID = GridView1.DataKeys[rowIndex].Values[0].ToString(); //GridView1.SelectedIndex.ToString();// .Values("ID");
            string Periode = ((TextBox)GridView1.Rows[e.RowIndex].Cells[1].Controls[0]).Text;
            string Tidsberegning = ((TextBox)GridView1.Rows[e.RowIndex].Cells[2].Controls[0]).Text; //Tidsberegning
            string Element = ((TextBox)GridView1.Rows[e.RowIndex].Cells[3].Controls[0]).Text; //Element
            string Værdi = ((TextBox)GridView1.Rows[e.RowIndex].Cells[4].Controls[0]).Text; //Værdi

            UpdateOrAddNewRecord(ID, Periode, Tidsberegning, Element, Værdi, true); // call update method
            GridView1.EditIndex = -1;
            BindGridView(); // Rebind GridView to reflect changes made 

            //int rowIndex = Convert.ToInt32(e.CommandArgument); // Get the current row
            //int bigStore = Convert.ToInt32(grdOrder.Rows[rowIndex].Cells[2].Text);

        }
    }
   
}