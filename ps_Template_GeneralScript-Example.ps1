<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER InsertOrRemove

    .EXAMPLE

    .NOTES
    Version history:

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)][string]$InsertOrRemove
)

$ErrorActionPreference = "Stop"

#@# Functions

#@# Main
$bProceed = $true
$sTimestamp = Get-Date -Format "yyyyMMddHHmmss"
$sProgDataFldr = ($Env:ProgramData + "\ps_UpdateThisPath")
$sLogFile = ($sProgDataFldr + "\Logs\" + (Get-Date -Format "yyyyMM") + "_INSERT-SCRIPT-NAME" + ".log")
$sConfigFile = ($PSScriptRoot + "\INSERT-CONFIG-NAME.conf")
$arrConfigHeaders = @("mailfrom","mailto","mailsubject","smtpserver")
$arrAlerts = @()

$sComputerName = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name ComputerName).ComputerName

# Define the email properties
$sEmailBody = "<center><h1>*** INSERT HEADER DESCRIPTION ***</h1></center>"
$sEmailBody += "<br>Session ID / Timestamp: " + $sTimestamp
$sEmailBody += "<br>Run from: " + $sComputerName
$sEmailBody += "<br>Script path: " + $MyInvocation.MyCommand.Path
$sEmailBody += "<br>Log path: " + $sLogFile
$sEmailBody += "<br>Script information: <a href=INSERT-WIKI-URL>INSERT-WIKI-URL</a>"
$sEmailBody += "<br>User: " + $Env:UserName
$sEmailBody += "<br><br>Action: INSERT ACTION ON RECIEVING THE EMAIL<br><br>"

Write-Output "`n`nINSERT-SCRIPT-NAME - AUTHOR - DATE - v<INSERT VERSION>"


#@# BEGIN

#@# Import the module ps_Module_GeneralScriptFunctions
try {
	Write-Output "*** Loading PowerShell module ps_Module_GeneralScriptFunctions"

	Import-Module ps_Module_CommonScriptFunctions -Verbose:$false

	Write-Output "`t+++ Success `n"
}
catch {
	$bProceed = $false

	$sErrMsg = ("Failed to load the PowerShell Module ps_Module_GeneralScriptFunctions. Error: " + (($Error[0].exception).toString()).replace("`r"," ").replace("`n"," "))

	$arrAlerts += New-Object -TypeName PSCustomObject -Property @{Type="Startup-Error";Result=$sErrMsg}

	Write-Output "`t--- $sErrMsg `n"
}


#@# Create the required folder structure
if ($bProceed -eq $true) {
	$bProceed = New-DataFolders -arrFolderPaths @($sProgDataFldr,(Split-Path $sLogFile)) -arrAlerts ([ref]$arrAlerts) -sTimestamp $sTimestamp
}

#@# Create the log file is it doesn't exist
if ($bProceed -eq $true) {
	$bProceed = Initialize-LogFile -sLogFile $sLogFile -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts)
}

#@# Load the config file
if ($bProceed -eq $true) {
	# This object will contain the successfully returned config headers
	$objConfig = New-Object -TypeName PSCustomObject

	$bProceed = Import-ConfigFile -sConfigFile $sConfigFile -objConfig ([ref]$objConfig) -arrConfigHeaders $arrConfigHeaders -sTimestamp $sTimestamp -sLogFile $sLogFile -arrAlerts ([ref]$arrAlerts)
}

#@# Load the required PowerShell modules
if ($bProceed -eq $true) {
	$bProceed = Import-PSModules -arrModuleNames @("ActiveDirectory") -sTimestamp $sTimestamp -sLogFile $sLogFile -arrAlerts ([ref]$arrAlerts)
}

#@# PROCESS

if ($bProceed -eq $true) {
	try {
		Write-Output "*** INSERT PROCESS DESCRIPTION"

		# Add success message to log
		$sLogMsg = ($sTimestamp + ",INFO,INSERT SUCCESS MESSAGE")
		$sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"

		Write-Output "`t+++ Success"
	}
	catch {
		$bProceed = $false

		$sErrMsg = "INSERT REASON. Error: " + (($Error[0].Exception.Message).toString()).replace("`r"," ").replace("`n"," ")
		$sLogMsg = ($sTimestamp + ",ERROR," + $sErrMsg)
		$sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"

		$arrAlerts += New-Object -TypeName PSCustomObject -Property @{Type="Startup-Error";Result=$sErrMsg}

		Write-Output "`t--- $sErrMsg"
	}
}

#@# END

#@# Finished processing. Sending email alerts if required.
if ($arrAlerts.Length -gt 0) {

	try {
		# Check that the config data is available - this is required as the "to/from/server" details should be contained within it
		if ($null -eq $objConfig) {
			throw "No config data discovered - unable to send alert emails"
		}
		else {
			$params_SendAlerts = @{
				arrAlerts=$arrAlerts
				objConfig=$objConfig
				sEmailBodyHead=$sEmailBody
				sTimestamp=$sTimestamp
				sLogFile=$sLogFile
			}

			$null = Send-AlertEmails @params_SendAlerts
		}
	}
	catch {
		$sErrMsg = "Failed to call Send-AlertEmails. Error: " + (($Error[0].Exception.Message).toString()).replace("`r"," ").replace("`n"," ")
		$sLogMsg = ($sTimestamp + ",ERROR," + $sErrMsg)
		Add-Content $sLogFile -Value $sLogMsg -ErrorAction "SilentlyContinue"
	}
}
else {
	Write-Output "`n*** No email alerts discovered `n"

	$sLogMsg = ($sTimestamp + ",INFO,No alerts discovered")
	Add-Content $sLogFile -Value $sLogMsg -ErrorAction "SilentlyContinue"
}


# Add closing statement to the log file
try {
	Write-Output "*** Writing closing statement to log file"

	$sLogMsg = ($sTimestamp + ",END,Script completed " + (Get-Date))
	Add-Content $sLogFile -Value $sLogMsg -ErrorAction "SilentlyContinue"

	Write-Output "`t+++ Success `n"
}
catch {
	Write-Output "`t--- Failed `n"
}


Write-Output "*** Finished `n`n`n"