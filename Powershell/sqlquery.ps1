function Runsql($query1)
{
$server = "oesmsqlt01\dirk"
#$query = "SELECT TOP 10 * FROM [meta].[Batch]"
$query = $query1
$database = "Dirk_test01"
#$title = "SELECT * FROM [meta].[Batch]"
# format-table
# Out-GridView
invoke-sqlcmd -serverinstance $server -database $database -query $query | Out-GridView
Write-Host $query 
#| Out-GridView 
#-title "SELECT * FROM [meta].[Batch]"
}