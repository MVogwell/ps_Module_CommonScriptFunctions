#Requires -Version 5.0

Function New-DataFolders() {
    <#
        .SYNOPSIS
        This PowerShell 5 function will attempt to create folder specified in the string array parameter arrFolderPaths. If the folder paths cannot be created, and a string array (arrAlerts) and the session timestamp (sTimestamp) are specified in the starting parameters then an the alert will be added to the array of alerts (arrAlerts).

        If a folder already exists then it will be ignored.

        .DESCRIPTION

        .PARAMETER arrFolderPaths
        This is a string array containing the paths of folders that are to be created

        .PARAMETER arrAlerts
        This is a string array that will be appended if the folder creation fails. This array can then be exported to email or log file

        .PARAMETER sTimestamp
        This is a string containing the script session timestamp (Get-Date -Format "yyyyMMddHHmmss")

        .EXAMPLE
        $bProceed = New-DataFolders -arrFolderPath @("c:\Temp\One","c:\Temp\Two")

        This will create the folder in the parameter "-arrFolderPath". If errors occur they will be displayed on screen but nowhere else


        .EXAMPLE
        $arrAlerts = @()
        $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"
        $bProceed = New-DataFolders -arrFolderPath @("c:\Temp\One","c:\Temp\Two") -arrAlerts $arrAlerts -sTimestamp $sTimestamp

        This will create the folder in the parameter "-arrFolderPath". If errors occur then details will be returned in the array arrAlerts

        .NOTES
        MVogwell

        Version history:
            0.1 - Development - pre testing - 20211204-1425
            0.2 - Initial release (Beta)
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][string[]]$arrFolderPaths,
        [Parameter(Mandatory=$false)][ref]$arrAlerts,
        [Parameter(Mandatory=$false)][string]$sTimestamp
    )

    BEGIN {
        $ErrorActionPreference = "Stop"

        # Write-Information requires the preference needs to be
        # set to Continue to display the messages
        $objInfoPref = $InformationPreference
        $InformationPreference = "Continue"

        $bRtn = $true
    }
    PROCESS {
        try {
            Write-Information "*** Creating data folders"

            foreach ($sFolderPath in $arrFolderPaths) {
                if ((Test-Path $sFolderPath) -eq $false) {
                    Write-Information "`t=== Creating $sFolderPath"

                    New-Item $sFolderPath -ItemType Directory -Force | Out-Null

                    Write-Information "`t`t+++ Successfully created folder"
                }
                else {	# The folder already exists
                    Write-Information "`t--- Folder $sFolderPath already exists"
                }
            }
        }
        catch {
            $bRtn = $false

            # Capture and add to the error message
            [string]$sErrMsg = ("Failed to create folder " + $sFolderPath + ". ")
            [string]$sErrMsg += ("Error: " + (($Global:Error[0].Exception.Message).toString()).replace("`r"," ").replace("`n"," "))

            # Add to the alerts if the function was called with the parameter arrAlerts
            if (($PSBoundParameters).Keys -contains "arrAlerts") {
               # Handle if the timestamp hasn't been passed to the function
                if (!(($PSBoundParameters).Keys -contains "sTimestamp")) {
                    $sTimestamp = "NotSet"
                }

                $arrAlerts.Value += New-Object -TypeName PSCustomObject -Property @{
                        Session= $sTimestamp.Value
                        Type="Startup-Error"
                        Result=$sErrMsg
                }
            }

            Write-Information "`t`t--- $sErrMsg"
        }
    }
    END {
        # Add line break after the completion (good or bad)
        Write-Information " "

        # Reset the InformationPreference value
        $InformationPreference = $objInfoPref

        return $bRtn
    }
}