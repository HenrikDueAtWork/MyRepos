Function ProcessProdKuber{}

Import-Module SQLPS -WarningAction SilentlyContinue
Import-module sqlascmdlets
Invoke-ASCmd -inputfile:"C:\Powershell\ProcessTogfoererFR.xmla" -server "oesmappt01\soem"
cd c:\powershell
exit powershell