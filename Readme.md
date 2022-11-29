# ps_Module_CommonScriptFunctions

This PowerShell v5.1 (and above) module provides basic script functions to increase the speed of development and provide stablity across multiple scripts.

The module provides the following cmdlets/functions:

* New-DataFolders
    * This function will create an array of folders, confirm that all have been created or (if specified in the startup parameters) return an alert that can be used by the function Send-AlertEmails. <br><br>
* Initialize-LogFile
    * This function will create a log file and add a top line reading `<Timestamp>,START,Computer: <ComputerName>` Note: this top line is both optional and configurable. If the log file fails to create an alert can be returned that can be used by Send-AlertEmails.  <br><br>
* Import-PSModules
    * This function will import an array of PowerShell modules. If a module fails to import an alert can be returned that can be used by Send-AlertEmails and an error message can be created in a log file.  <br><br>
* Import-ConfigFile
    * This function will import a Json formatted config file and return the data as a PSCustomObject. If the config file fails to load or parse an alert can be returned that can be used by Send-AlertEmails and an error message can be created in a log file. <br><br>
* Send-AlertEmails
    * This function will attempt to send email alerts based on a provided config containing the mail send information as well as an array object containing PSCustomObjects. The alerts will be sent in HTML format CSS formatting on the table. If the alert email fails to send an error message can be saved to a log file. <br><br>
* Test-QuickTcpConnection
	* This function is like the built-in cmdlet Test-NetConnection but quicker!<br><br><br>

# Installing the module

The published module is available at https://www.powershellgallery.com/packages/ps_Module_CommonScriptFunctions. To install the module run (in PowerShell):

`Install-Module -Name ps_Module_CommonScriptFunctions`

If you don't have administrative privileges to your machine you can run:

`Install-Module -Name ps_Module_CommonScriptFunctions -Scope CurrentUser`

If you don't have access to PowerShell gallery you can:
* Download the script from the git repo https://github.com/MVogwell/ps_Module_CommonScriptFunctions
* Place the extracted files into %USERPROFILE\Documents\PowerShell\Modules\ps_Module_CommonScriptFunctions

<br><br>

# How to use the module functions
Included in the module folder is an example script file "ps_Template_GeneralScript-Example.ps1" which contains an example of using the script file. Additionally, each function has a in-file help which can be accessed using:

`Import-Module ps_Module_CommonScriptFunctions`

`help <command name>`

Within the module is an example script template "ps_Template_GeneralScript-Example.ps1" and an example config file "ps_Template_GeneralScript-Example.conf" which show how the functions can be used and can be used to speed up development.

<br><br>

