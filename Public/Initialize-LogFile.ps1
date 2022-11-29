#Requires -Version 5.0

Function Initialize-LogFile() {
    <#
        .SYNOPSIS
        This PowerShell function will attempt to create a log file if it doesn't exist. It will then write a header to the log file.

        The function will return true (success) or false (failed). If arrAlerts is passed it will also return any errors into the array

        .PARAMETER sLogFile
        This is a string containing the log file path

        .PARAMETER sTimestamp
        This is a string containing the script session timestamp (Get-Date -Format "yyyyMMddHHmmss")

        .PARAMETER arrAlerts
        Optional: This is a string ARRAY passed as a reference that will be appended if the folder creation fails. This array can then be exported to email or log file

        .PARAMETER DoNotWriteTopLine
        Optional. Specifying this SWITCH parameter will prevent a string value "Starting" line from being written to the log file.

        .PARAMETER sTopLineText
        Optional: This is a string value that will, if specified, be written to the top of the log file instead of the default value which is: <Timestamp>,INFO,START - <ComputerName>. Note this will only work if DoNotWriteTopLine is not specified.

        .EXAMPLE
        $bProceed = Initialize-LogFile -sLogFile "c:\temp\logfile.txt"

        This will create a log file and write a start entry. If anything fails it will return false and display the reason on screen but won't return an alert

        .EXAMPLE
        $arrAlerts = @()
        $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"
        $bProceed = Initialize-LogFile -sLogFile "c:\temp\logfile.txt" -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts)

        This will create a log file and write a start entry. If errors occur then details will be returned in the array arrAlerts

        .NOTES
        MVogwell

        Version history:
            0.1 - Development - pre testing - 20211204-2134
            0.2 - Updated with option to manually specify the log file top line
            0.3 - Added param bShowInfo to supress messages on screen
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][string]$sLogFile,
        [Parameter(Mandatory=$true)][string]$sTimestamp,
        [Parameter(Mandatory=$false)][switch]$DoNotWriteTopLine,
        [Parameter(Mandatory=$false)][string]$sTopLineText,
        [Parameter(Mandatory=$false)][ref]$arrAlerts,
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
        if ([string]::IsNullOrEmpty($sTimestamp)) {
            $sTimestamp = "NotSet"
        }
    }
    PROCESS {
        try {
            Write-Information "*** Checking the log file"

            if ((Test-Path $sLogFile) -eq $false) {
                Write-Information "`t=== Creating log file"

                New-Item -Path $sLogFile -ItemType File -Force | Out-Null

                Write-Information "`t`t+++ Success: $sLogFile `n"
            }
            else {
                Write-Information "`t+++ Log file exists: $sLogFile `n"
            }

            # Create the log file starting entry unless the function has been started with DoNotWriteTopLine
            if (!($DoNotWriteTopLine -eq $true)) {
                Write-Information "`t=== Writing header line"

                if ([string]::IsNullOrEmpty($sTopLineText)) {
                    $sLogMsg = ($sTimestamp + ",START,Computer: " + (([System.Net.Dns]::GetHostByName($sComputerName)).HostName))
                    $sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"
                }
                else {
                    $sTopLineText | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Continue"
                }

                Write-Information "`t`t+++ Succcess `n"
            }
            else {
                Write-Verbose "`t=== Skipping header line creation `n"
            }
        }
        catch {
            $bRtn = $false

            # Capture and add to the error message
            [string]$sErrMsg = ("Failed to create or write to the log file " + $sLogFile + ". ")
            [string]$sErrMsg += ("Error: " + (($Global:Error[0].Exception.Message).toString()).replace("`r"," ").replace("`n"," "))

            # Add to the alerts if the function was called with the parameter arrAlerts
            if (($PSBoundParameters).Keys -contains "arrAlerts") {
                $arrAlerts.Value += New-Object -TypeName PSCustomObject -Property @{
                        Session= $sTimestamp
                        Type="Startup-Error"
                        Result=$sErrMsg
                }
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