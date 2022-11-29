[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
param()

BeforeAll {
    # Import the script file
    $sPath = ($PSScriptRoot).Replace("Tests","Public") + "\Send-AlertEmails.ps1"

    . $sPath

    # Initialise required variables
    $sTimestamp = Get-Date -Format "yyyyMMddHHmmss"

    $objConfig = [PSCustomObject] @{
        mailfrom = "sending-address@domain.com"
        mailto = "recipient-address@domain.com"
        mailSubject = "Mail Subject"
        smtpserver = "SMTP1234.NoSuchMailServerHereAtAllYep101010101.com"
    }

    $objAlert = [PSCustomObject] @{
        Session = "20221128160000"
        Type = "Test alert"
        Result = "This is a test alert"
    }

    $arrAlerts = @($objAlert)

    $sEmailBodyHead = "Test 123"
}

Describe "Send-AlertEmails" {
    Context "Send alerts - mock send-mailmessage" {
        BeforeAll {
            # Stop it attempting to send a real email
            Mock Send-MailMessage { }

            $sLogFile = "TestDrive:\Test.log"
            $null = New-Item $sLogFile -ItemType File            

            $bResponse = Send-AlertEmails -arrAlerts $arrAlerts -objConfig $objConfig -sEmailBodyHead $sEmailBodyHead -sTimestamp $sTimestamp -sLogFile $sLogFile -bShowInfo $false
        }

        It "Should return true" {
            $bResponse | Should -be $true
        }

        It "Should write success to log file" {
            (Get-Content $sLogFile) | Should -BeLike "*Successfully emailed alerts*"
        }

        AfterAll {
            Remove-Item $sLogFile
        }
    }

    Context "Send alerts - bad server address" {
        BeforeAll {
            $sLogFile = "TestDrive:\Test.log"
            $null = New-Item $sLogFile -ItemType File

            $bResponse = Send-AlertEmails -arrAlerts $arrAlerts -objConfig $objConfig -sEmailBodyHead $sEmailBodyHead -sTimestamp $sTimestamp -sLogFile $sLogFile -bShowInfo $false
        }

        It "Should return false" {
            $bResponse | Should -be $false
        }

        It "Should write error to log file" {
            (Get-Content $sLogFile) | Should -BeLike "*Failed to send alert emails!*No such host is known*"
        }

        AfterAll {
            Remove-Item $sLogFile
        }
    }
}

AfterAll {
    Remove-Item Function:\Send-AlertEmails
}