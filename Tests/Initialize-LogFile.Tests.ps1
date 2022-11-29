[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\Initialize-LogFile.ps1"

    . $sPath

    $sLogFilePath = "TestDrive:\Test.log"
    $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"
}

Describe "Initialize-LogFile" {
    Context "Good log file" {
        BeforeAll {
            $bResponse = Initialize-LogFile -sLogFile $sLogFilePath -sTimestamp $sTimestamp -bShowInfo $false
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        It "Should create a log file" {
            Test-Path -Path $sLogFilePath -ErrorAction "SilentlyContinue" | Should -be $true
        }

        It "Should place the timestamp at the start of the log file" {
            (Get-Content $sLogFilePath -ErrorAction "SilentlyContinue") -match "^$($sTimestamp)" | Should -be $true
        }

        AfterAll {
            Remove-Item $sLogFilePath
        }
    }

    Context "Bad log file path" {
        BeforeAll {
            $arrAlerts = @()
            $sBadLogFilePath = "NoDrive:\nofile.txt"
            $bResponse = Initialize-LogFile -sLogFile $sBadLogFilePath -sTimestamp $sTimestamp -arrAlerts ([ref]$arrAlerts) -bShowInfo $false
        }

        It "Should return false" {
            $bResponse | Should -be $false
        }

        It "Should return an alert" {
            $arrAlerts[0].Result | Should -BeLike "Failed to create or write to the log file NoDrive:\nofile.txt*"
        }
    }

    Context "Create log with no header line" {
        BeforeAll {
            $bResponse = Initialize-LogFile -sLogFile $sLogFilePath -sTimestamp $sTimestamp -DoNotWriteTopLine -bShowInfo $false
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        It "Should create a log file" {
            Test-Path -Path $sLogFilePath -ErrorAction "SilentlyContinue" | Should -be $true
        }

        It "Should not put anything in the file" {
            [string]::IsNullOrEmpty((Get-Content $sLogFilePath -ErrorAction "SilentlyContinue")) | Should -be $true
        }

        AfterAll {
            Remove-Item $sLogFilePath
        }
    }

    Context "Custom header line" {
        BeforeAll {
            $sCustomHeaderLine = "Item1,Item2,Item3"
            $bResponse = Initialize-LogFile -sLogFile $sLogFilePath -sTimestamp $sTimestamp -sTopLineText $sCustomHeaderLine -bShowInfo $false
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        It "Should create a log file" {
            Test-Path -Path $sLogFilePath -ErrorAction "SilentlyContinue" | Should -be $true
        }

        It "Should place a custom header at the top of the log file" {
            (Get-Content $sLogFilePath -ErrorAction "SilentlyContinue") | Should -be "Item1,Item2,Item3"
        }

        AfterAll {
            Remove-Item $sLogFilePath
        }
    }    
}

AfterAll {
    Remove-Item Function:\Initialize-LogFile
}