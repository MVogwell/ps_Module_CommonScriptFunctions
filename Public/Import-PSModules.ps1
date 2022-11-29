#Requires -Version 5.0

Function Import-PSModules() {
    <#
        .SYNOPSIS
        This PowerShell function will attempt to load PowerShell modules

        The function will return true (success) or false (failed). If arrAlerts is passed it will also return any errors into the array

        .PARAMETER arrModuleNames
        This is a string ARRAY of the module names to load

        .PARAMETER sTimestamp
        This is a string containing the script session timestamp (Get-Date -Format "yyyyMMddHHmmss")

        .PARAMETER sLogFile
        This is a string containing the full path of the log file to write messages into.

        .PARAMETER arrAlerts
        This is a string ARRAY passed as a reference that will be appended if the folder creation fails. This array can then be exported to email or log file

        .EXAMPLE
        $bProceed = Import-PSModules -arrModuleNames @("ActiveDirectory","Microsoft.PowerShell.SecretManagement")
        This will import PowerShell modules referenced in arrModuleNames. If anything fails it will return false and display the reason on screen but won't return an alert

        .EXAMPLE
        $arrAlerts = @()
        $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"
        $bProceed = Import-PSModules -arrModuleNames @("ActiveDirectory","Microsoft.PowerShell.SecretManagement") -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts)

        This will create the folder in the parameter "-arrFolderPath". If errors occur then details will be returned in the array arrAlerts.

        .NOTES
        MVogwell

        Version history:
            0.1 - Development - pre testing - 20211204-2134
            1.0 - Release version - 20220111-0933
            1.1 - Added param bShowInfo to supress messages on screen
    #>

    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][string[]]$arrModuleNames,
        [Parameter(Mandatory=$false)][string]$sTimestamp,
        [Parameter(Mandatory=$false)][string]$sLogFile,
        [Parameter(Mandatory=$false)][ref]$arrAlerts,
        [Parameter(Mandatory=$false)][bool]$ShowVerbose,
        [Parameter(Mandatory=$false)][bool]$bShowInfo = $true
    )

    BEGIN {
        $ErrorActionPreference = "Stop"

        # Write-Information requires the preference needs to be
        # set to Continue to display the messages
        if ($bShowInfo -eq $true) {
            $objInfoPref = $InformationPreference
            $InformationPreference = "Continue"
        }

        # Set the default return flag value
        $bRtn = $true

        # Handle if the timestamp is null or empty
        if (!(($PSBoundParameters).Keys -contains "sTimestamp")) {
            $sTimestamp = "NotSet"
        }
    }
    PROCESS {
        try {
            Write-Information "*** Importing PowerShell Modules"

            foreach ($sPSModule in $arrModuleNames) {
                Write-Information "`t=== Module: $sPSModule"

                Import-Module $sPSModule -WarningAction "SilentlyContinue" -Scope Global

                # If the log file path has been specified in the parameters write the success log message
                if (($PSBoundParameters).Keys -contains "sLogFile") {
                    [string]$sLogMsg = ($sTimestamp + ",INFO,Successfully loaded PowerShell module " + $sPSModule)
                    $sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"
                }

                Write-Information "`t`t+++ Success `n"
            }
        }
        catch {
            $bRtn = $false

            # Capture and add to the error message
            [string]$sErrMsg = ("Failed to load PowerShell module " + $sPSModule + ". ")
            [string]$sErrMsg += ("Error: " + (($Global:Error[0].Exception.Message).toString()).replace("`r"," ").replace("`n"," "))

            # Add to the alerts if the function was called with the parameter arrAlerts
            if (($PSBoundParameters).Keys -contains "arrAlerts") {
                $arrAlerts.Value += New-Object -TypeName PSCustomObject -Property @{
                        Session= $sTimestamp
                        Type="Startup-Error"
                        Result=$sErrMsg
                }
            }

            # If the log file path has been specified in the parameters write the error log message
            if (($PSBoundParameters).Keys -contains "sLogFile") {
                [string]$sLogMsg = ($sTimestamp + ",ERROR," + $sErrMsg)
                $sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"
            }

            Write-Information "`t`t--- $sErrMsg `n"
        }
    }
    END {
        # Reset the InformationPreference value
        if ($bShowInfo -eq $true) {
            $InformationPreference = $objInfoPref
        }

        return $bRtn
    }
}