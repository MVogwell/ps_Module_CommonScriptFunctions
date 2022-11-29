[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\Import-ConfigFile.ps1"

    . $sPath

    $sConfigData = '{ "Item1":"Item1Data","Item2":["Item2Data-Element1","Item2Data-Element1"] }'

}

Describe "Import-ConfigFile" {
    Context "Base params" {
        BeforeAll {
            $sTestConfigPath = "TestDrive:\Config.json"
            Set-Content -Path $sTestConfigPath -Value $sConfigData

            $objConfigResponse = [PSCustomObject] @{}

            $objResponse = Import-ConfigFile -sConfigFile $sTestConfigPath -objConfig ([ref]$objConfigResponse) -bShowInfo $false
        }

        It "Should return true" {
            $objResponse | Should -be $true
        }

        It "Should respond with data in the config response" {
            $objConfigResponse.PSObject.Properties.Name -contains "Item1" | Should -be $true
            $objConfigResponse.PSObject.Properties.Name -contains "Item2" | Should -be $true
        }
        AfterAll {
            Remove-Item $sTestConfigPath
        }
    }

    Context "Config file doesn't exist and alerts returned" {
        BeforeAll {
            $sTestConfigPath = "TestDrive:\DoesNotExist.json"

            $objConfigResponse = [PSCustomObject] @{}

            $arrAlerts = @()

            $objResponse = Import-ConfigFile -sConfigFile $sTestConfigPath -objConfig ([ref]$objConfigResponse) -arrAlerts ([ref]$arrAlerts) -bShowInfo $false
        }

        It "Should return false" {
            $objResponse | Should -be $false
        }

        It "Should return an error in the alerts array" {
            $arrAlerts[0].Result | Should -BeLike "Failed to load the config file TestDrive:\DoesNotExist.json*"
        }
    
        AfterAll {
            Remove-Variable sTestConfigPath
        }
    }

    Context "Test good config headers" {
        BeforeAll {
            $sTestConfigPath = "TestDrive:\Config.json"
            Set-Content -Path $sTestConfigPath -Value $sConfigData

            $objConfigResponse = [PSCustomObject] @{}
            $arrConfigHeaders = @("Item1","Item2")

            $objResponse = Import-ConfigFile -sConfigFile $sTestConfigPath -objConfig ([ref]$objConfigResponse) -arrConfigHeaders $arrConfigHeaders -bShowInfo $false
        }

        It "Should return true" {
            $objResponse | Should -be $true
        }
        
        AfterAll {
            Remove-Item $sTestConfigPath
        }
    }

    Context "Test bad config headers" {
        BeforeAll {
            $sTestConfigPath = "TestDrive:\Config.json"
            Set-Content -Path $sTestConfigPath -Value $sConfigData

            $objConfigResponse = [PSCustomObject] @{}

            $arrConfigHeaders = @("ItemABC","ItemXYZ")

            $arrAlerts = @()

            $objResponse = Import-ConfigFile -sConfigFile $sTestConfigPath -objConfig ([ref]$objConfigResponse) -arrConfigHeaders $arrConfigHeaders -arrAlerts ([ref]$arrAlerts) -bShowInfo $false
        }

        It "Should respond with false" {
            $objResponse | Should -be $false
        }

        It "Should contain the missing header in the alert response" {
            $arrAlerts[0].Result | Should -BeLike '*Missing header entry in config: ItemABC*'
        }

        AfterAll {
            Remove-Item $sTestConfigPath
        }
    }

    Context "Test logging to file" {
        BeforeAll {
            $sTestConfigPath = "TestDrive:\Config.json"
            Set-Content -Path $sTestConfigPath -Value $sConfigData

            $sLogFile = "TestDrive:\LogFile.txt"
            $null = New-Item -Path $sLogFile -ItemType File

            $objConfigResponse = [PSCustomObject] @{}
            $arrConfigHeaders = @("Item1","Item2")   
            
            $sTimeStamp = Get-Date -Format "yyyyMMddHHmmss"

            $objResponse = Import-ConfigFile -sConfigFile $sTestConfigPath -objConfig ([ref]$objConfigResponse) -sTimestamp $sTimeStamp -sLogFile $sLogFile -bShowInfo $false
        }

        It "Should return true" {
            $objResponse | Should -be $true
        }

        It "Should write data to the log file" {
            (Get-Item $sLogFile).Length | Should -BeGreaterThan 0
        }

        It "Should write the timestamp to the log file first" {
            (Get-Content $sLogFile) -match "^$($sTimestamp)" | Should -be $true
        }

        AfterAll {
            Remove-Item $sTestConfigPath
        }
    }
}

AfterAll {
    Remove-Item function:\Import-ConfigFile
}