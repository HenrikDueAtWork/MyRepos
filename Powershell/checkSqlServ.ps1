function chkSqlServ
{
$array = @("test1", "test2", "test3")
"First array value: " + $array[0]
"Second array value: " + $array[1]
"Third array value: " + $array[2]

foreach ($element in $array) {
	$element}

#$servers = 'oesmsqlt01','oesmsqlp01'
#Get-ServiceStatus -server $servers
#gsv -cn $servers -Name *mssql$*
}
# {
# @{'oesmsqlt01' = 'mssql'}.GetEnumerator() | ForEach-Object 

# {
#gsv -cn $_.Name -Name $_.Value 
# gsv -cn $_.Name -Name $_.Value 
#| format-table Name, MachineName, Status -autosize
#gsv *mssql$* -cn "oesmsqlp01"
# } 
#| format-table Name, MachineName, Status -autosize
# }