[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\Import-PSModules.ps1"

    . $sPath
}

Describe "Import-PSModules" {
    Context "Module exists" {
        BeforeAll {
            $sLogFile = "TestDrive:\Test.log"
            $null = New-Item $sLogFile -ItemType File

            $arrModuleNames = @("DnsClient","NetAdapter")

            $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"

            $bResult = Import-PSModules -arrModuleNames $arrModuleNames -bShowInfo $false -sTimestamp $sTimestamp -sLogFile ([ref]$sLogFile)
        }

        It "Should return true" {
            $bResult | Should -Be $true
        }

        It "Should return success message in the log file" {
            (Get-Content $sLogfile) | Should -BeLike "*Successfully loaded PowerShell module*"
        }

        AfterAll {
            Remove-Item $sLogFile -ErrorAction "SilentlyContinue"
            Remove-Variable sLogFile,arrModuleNames,sTimestamp,bResult -ErrorAction "SilentlyContinue"
        }
    }
    Context "Bad Module name" {
        BeforeAll {
            $sLogFile = "TestDrive:\Test.log"
            $null = New-Item $sLogFile -ItemType File

            $arrAlerts = @()

            $arrModuleNames = @("NoSuchModuleHereAtAll")

            $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"

            $bResult = Import-PSModules -arrModuleNames $arrModuleNames -bShowInfo $false -sTimestamp $sTimestamp -sLogFile ([ref]$sLogFile) -arrAlerts ([ref]$arrAlerts)
        }

        It "Should return false" {
            $bResult | Should -Be $false
        }

        It "Should return success message in the log file" {
            (Get-Content $sLogfile) | Should -BeLike "*Failed to load PowerShell module*"
        }

        It "Should return an alert" {
            $arrAlerts[0].Result | Should -BeLike "*Failed to load PowerShell module*"
        }

        AfterAll {
            Remove-Item $sLogFile -ErrorAction "SilentlyContinue"
            Remove-Variable sLogFile,arrModuleNames,sTimestamp,bResult -ErrorAction "SilentlyContinue"            
        }
    }
}

AfterAll {
    Remove-Item Function:\Import-PSModules
}