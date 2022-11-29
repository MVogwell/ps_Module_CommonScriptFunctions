[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\New-DataFolders.ps1"

    . $sPath
}

Describe "New-DataFolders" {
    Context "Good folder paths" {
        BeforeAll {
            $arrFolders = @("TestDrive:\Folder1","TestDrive:\Folder2")

            $bResponse = New-DataFolders -arrFolderPath $arrFolders -bShowInfo $false
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        It "Should create required folders" {
            (Test-Path "TestDrive:\Folder1") | Should -be $true
            (Test-Path "TestDrive:\Folder2") | Should -be $true
            (Test-Path "TestDrive:\Folder3") | Should -be $false
        }

        AfterAll {
            $arrFolders | ForEach-Object {
                Remove-Item $_ -Force
            }
        }
    }

    Context "Bad folder paths" {
        BeforeAll {
            $arrAlerts = @()

            $arrFolders = @("NoDrive:\Folder1","NoDrive:\Folder2")

            $bResponse = New-DataFolders -arrFolderPath $arrFolders -arrAlerts ([ref]$arrAlerts) -bShowInfo $false
        }

        It "Should return false" {
            $bResponse | Should -be $false
        }

        It "Should return an error in the alert" {
            $arrAlerts[0].Result | Should -BeLike 'Failed to create folder NoDrive:\Folder1*'
        }
    }
}

AfterAll {
    Remove-Item Function:\New-DataFolders
}