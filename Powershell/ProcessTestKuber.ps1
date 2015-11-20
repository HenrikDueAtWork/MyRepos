# $Host.UI.RawUI.BackgroundColor = "DarkBlue"
cls
$path =  Resolve-Path .\ 
$logPath = "\Log"
$newPath = "$path\Log"
write-host $newPath
if (!(Test-Path -Path $newPath) ) { New-Item -ItemType directory -Path $newPath }
$Logfile = "\Log\log"
$LogExtension = ".log"
$LogError = "Kørsel fejlet"
$LogOk = "Kørsel afsluttet uden fejl"
$LogTid = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
Try{
#Set-Executionpolicy Unrestricted
# Import-Module SQLPS -WarningAction SilentlyContinue
# Import-module sqlascmdlets
Write-Host "Processerer kuber"
# Invoke-ASCmd -inputfile:$Path"\ProcessTogfoererFR.xmla" -server "oesmappt01\soem"
#denne tekst får script til at fejle 
Add-content $Path$Logfile$LogTid$LogExtension -value $LogOk
Write-Host "Afsluttet uden fejl"
Write-Host "Tryk på en vilkårlig tast for at fortsætte ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
#exit
}
Catch{
Add-content $Logfile$LogTid$LogExtension -value $LogError
Write-Host "Fejlet"
Write-Host "Tryk på en vilkårlig tast for at fortsætte ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}