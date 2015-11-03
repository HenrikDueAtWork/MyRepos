$Host.UI.RawUI.BackgroundColor = "DarkBlue"
$Path =  Resolve-Path .\ 
$Logfile = "\Log\log"
$LogExtension = ".log"
$LogError = "Kõrsel fejlet"
$LogOk = "Kõrsel afsluttet uden fejl"
$LogTid = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
Import-Module SQLPS -WarningAction SilentlyContinue
Import-module sqlascmdlets
# Function ProcessProdKuber{}
Try{
#Set-Executionpolicy Unrestricted
# Import-Module SQLPS -WarningAction SilentlyContinue
# Import-module sqlascmdlets
Write-Host "Processerer kuber"
# Invoke-ASCmd -inputfile:$Path"\ProcessTogfoererFR.xmla" -server "oesmappt01\soem"
#denne tekst f√•r script til at fejle 
Add-content $Path$Logfile$LogTid$LogExtension -value $LogOk
Write-Host "Afsluttet uden fejl"
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#exit
}
Catch{
Add-content $Logfile$LogTid$LogExtension -value $LogError
Write-Host "Fejlet"
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}