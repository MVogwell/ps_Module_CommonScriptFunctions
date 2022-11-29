#Requires -Version 5.0

Function Import-ConfigFile() {
    <#
        .SYNOPSIS
        This PowerShell function will attempt to load and parse a json config file and check the expected parameters exist

        The function will return true (success) or false (failed). If arrAlerts is passed it will also return any errors into the array

        .PARAMETER sConfigFile
        Mandatory: This is a string containing the path of the config file (json format)

        .PARAMETER objConfig
        Mandatory: This is an EMPTY PSCustomObject object passed as a reference to the function. If successful the function will return the array object of config entries in the array

        .PARAMETER arrConfigHeaders
        Optional: This is a string ARRAY of the expected headers from the json config file

        .PARAMETER sTimestamp
        Optional: This is a string containing the script session timestamp (Get-Date -Format "yyyyMMddHHmmss"). This should be specified if the log file or alerts parameters are used.

        .PARAMETER sLogFile
        Optional: This is a string containing the full path of the log file to write messages into.

        .PARAMETER arrAlerts
        Optional: This is a string ARRAY passed as a reference that will be appended if the folder creation fails. This array can then be exported to email or log file

        .EXAMPLE
        $objConfig = New-Object -TypeName PSCustomObject

        $bProceed = Import-ConfigFile -sConfigFile "c:\Test\TestConfig.json" -objConfig ([ref]$objConfig)

        This will load the config file. If anything fails it will return false and display the reason on screen but won't return an alert
        The config entries will be returned in $objConfig

        .EXAMPLE
        $arrAlerts = @()
        $objConfig = New-Object -TypeName PSCustomObject
        $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"


        $bProceed = Import-ConfigFile -sConfigFile "c:\Test\TestConfig.json" -objConfig ([ref]$objConfig) -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts)

        This will load the config file and return the values in objConfig. If errors occur then details will be returned in the array arrAlerts.

        .EXAMPLE
        $arrAlerts = @()
        $arrConfigHeaders = @("Header1","Header2")
        $objConfig = New-Object -TypeName PSCustomObject
        $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"


        $bProceed = Import-ConfigFile -sConfigFile "c:\Test\TestConfig.json" -objConfig ([ref]$objConfig) -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts) -arrConfigHeaders $arrConfigHeaders

        This will load the config file and return the values in objConfig. It will return an error if the config file doesn't contain the haders listed in he array arrConfigHeaders. If errors occur then details will be returned in the array arrAlerts.


        .NOTES
        MVogwell

        Version history:
            0.1 - Development - pre testing - 20211206-1205
            0.2 - Release version
            0.3 - Added param bShowInfo to supress messages on screen
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter(Mandatory=$true)][string]$sConfigFile,
        [Parameter(Mandatory=$true)][ref]$objConfig,
        [Parameter(Mandatory=$false)][string[]]$arrConfigHeaders,
        [Parameter(Mandatory=$false)][string]$sTimestamp,
        [Parameter(Mandatory=$false)][string]$sLogFile,
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
        if (!(($PSBoundParameters).Keys -contains "sTimestamp")) {
            $sTimestamp = "NotSet"
        }
    }
    PROCESS {
        try {
            Write-Information "*** Loading the script config file"

            # This loads the config file and parses it from json format to PSCustomObject and returns the data in the objConfig ref variable
            $objConfigTemp = Get-Content $sConfigFile | ConvertFrom-Json

            # Check that some data has been returned
            if ($null -eq $objConfig) {
                $sThrowMsg = "No data has been discovered in the config file"
                throw $sThrowMsg
            }

            # Check the config headers exist - this is only checked if the function was started with the parameter arrConfigHeaders
            if (($PSBoundParameters).Keys -contains "arrConfigHeaders") {
                $arrConfigHeaders | Foreach-Object {
                    if (!(($objConfigTemp | Get-Member -MemberType Properties).Name -contains $_)) {
                        $sThrowMsg = ("Missing header entry in config: " + $($_))
                        throw $sThrowMsg
                    }
                }
            }

            # Return the data to the ref object passed to the function
            $objConfig.Value = $objConfigTemp


            # If the log file path has been specified in the parameters write the success log message
            if (($PSBoundParameters).Keys -contains "sLogFile") {
                [string]$sLogMsg = ($sTimestamp + ",INFO,Successfully loaded source business config data file " + $sConfigFile)
                $sLogMsg | Out-File $sLogFile -Encoding utf8 -Append -ErrorAction "Stop"
            }

            Write-Information "`t+++ Success `n"
        }
        catch {
            $bRtn = $false

            # Capture and add to the error message
            [string]$sErrMsg = ("Failed to load the config file " + $sConfigFile + ". ")
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

            Write-Information "`t--- $sErrMsg `n"
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