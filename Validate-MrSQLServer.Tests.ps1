﻿#Requires -Version 3.0 -Modules MrToolKit
[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName = $env:COMPUTERNAME,

    [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
)

foreach ($Computer in $ComputerName) {

    Describe "Validation of a SQL Server: $Computer" {
        
        try {
            $Session = New-PSSession -ComputerName $Computer -Credential $Cred -ErrorAction Stop
        }
        catch {
            Write-Warning -Message "Unable to establish a connection to: '$Computer'."
        }

        It 'The SQL Server service should be running' {
            (Invoke-Command -Session $Session {Get-Service -Name MSSQLSERVER}).status |
            Should be 'Running'
        }

        It 'The SQL Server agent service should be running' {
            (Invoke-Command -Session $Session {Get-Service -Name SQLSERVERAGENT}).status  |
            Should be 'Running'
        }

        It 'The SQL Server service should be listening on port 1433' {
            (Test-Port -Computer $Computer -Port 1433).Open |
            Should be $true
        }

        It 'Should be able to query information from the SQL Server' {(
            Invoke-Command -Session $Session {
                if (Get-PSSnapin -Name SqlServerCmdletSnapin* -Registered -ErrorAction SilentlyContinue) {
                    Add-PSSnapin -Name SqlServerCmdletSnapin*
                }
                elseif (Get-Module -Name SQLPS -ListAvailable){
                    Import-Module -Name SQLPS -DisableNameChecking -Function Invoke-Sqlcmd
                }
                else {
                    Throw 'SQL PowerShell Snapin or Module not found'
                }
                Invoke-SqlCmd -Database Master -Query "select name from sys.databases where name = 'master'"
            }
        ).name |
            Should be 'master'
        }

        Remove-PSSession -Session $Session

    }

}