#Requires -Version 5.0

Function Test-QuickTcpConnection () {
    <#
        .SYNOPSIS
        This function is similar to the cmdlet Test-NetConnection but returns a result quicker. The timeout setting can also be configured.

        .DESCRIPTION

        .PARAMETER sComputerName
        [Mandatory] This string parameter should specify the computer name (or IP address) to test

        .PARAMETER iPort
        [Mandatory] This integer parameter should specify the TCP port number to test

        .PARAMETER iTimeoutMS
        [Optional] This integer parameter should specify the number of milliseconds to wait before timing out. The default is 3500ms (3.5 seconds)

        .EXAMPLE
        $bResult = Test-QuickTcpConnection -sComputerName "127.0.0.1" -iPort 139

        This will check whether TCP port 139 is on open on the local machine

        .EXAMPLE
        $bResult = Test-QuickTcpConnection -sComputerName "127.0.0.1" -iPort 139 -iTimeoutMS 10

        This will check whether TCP port 139 is on open on the local machine which must respond in 10ms otherwise it will fail

        .NOTES
        MVogwell

        Version history:
            0.1 - Development
            1.0 - Initial release
    #>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)][string]$sComputerName,
		[Parameter(Mandatory=$true)][int]$iPort,
        [Parameter(Mandatory=$false)][int]$iTimeoutMS = 3500
	)

    # Version 1.0 - Initial release
    # Purpose: Tests whether a TCP connection is available. This is a lot quicker than running Test-NetConnection!
	
	BEGIN {
        # This is the return boolean value
		$bRtn = $true
	}
	PROCESS {
		try {
			Write-Verbose "*** Connecting to $sComputerName on TCP port $iPort"

            # Connect to the address and port using System.Net.Sockets.TCPClient
			$objTcpClient = New-Object -TypeName System.Net.Sockets.TCPClient
			$AsyncResult  = $objTcpClient.BeginConnect($sComputerName,$iPort,$null,$null)
			$bWait = $AsyncResult.AsyncWaitHandle.WaitOne($iTimeoutMS)
		}
		catch {
			$bRtn = $false
		}
		
		if ($bRtn -eq $true) {
			if ($bWait -eq $true) {
				Try  {
					$null  = $objTcpClient.EndConnect($AsyncResult)
				} 
				Catch  {
					# Doesn't do anything but needed a line in the catch block
					$bWait = $null
				} 
				Finally  {
					$bRtn = $objTcpClient.Connected
				}
			}
			else {
				$bRtn = $objTcpClient.Connected
			}
		}
		
		# Close the connection
		try {
			Write-Verbose "`t+++ Connected: $bRtn"

			$objTcpClient.Dispose()

			Write-Verbose "`t+++ Successfully disposed of connection"
		}
		catch {
			Write-Verbose "`t--- Failed to dispose of the TCPClient"
		}
	}
	END {
		return $bRtn
	}
}