Function Test-QuickTcpConnection () {
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