[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\Test-QuickTcpConnection.ps1"

    . $sPath

    $arrOpenPorts = Get-NetTCPConnection -State Listen | Where-Object localAddress -eq "0.0.0.0"

    $arrBadPorts = @(1234,4321,71624)
}

Describe "Test-QuickTcpConnection" {
    Context "Port Available" {
        BeforeAll {
            $iPort = $arrOpenPorts | Select-Object -First 1 -ExpandProperty LocalPort

            $bResponse = Test-QuickTcpConnection -sComputerName "127.0.0.1" -iPort $iPort
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        AfterAll {
            Remove-Variable iPort, bResponse -ErrorAction "SilentlyContinue"
        }
    }

    Context "Port NOT Available" {
        BeforeAll {
            foreach ($iPossPort in $arrBadPorts) {
                if (!($arrOpenPorts.LocalPort -contains $iPossPort)) {
                    $iPort = $iPossPort
                    break
                }
            }

            $bResponse = Test-QuickTcpConnection -sComputerName "127.0.0.1" -iPort $iPort
        }

        It "Should return false" {
            $bResponse | Should -be $false
        }

        AfterAll {
            Remove-Variable iPort, bResponse -ErrorAction "SilentlyContinue"
        }
    }

}

AfterAll {
    Remove-Item Function:\Test-QuickTcpConnection
}

