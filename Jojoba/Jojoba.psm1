[CmdletBinding()]
param (
    [bool] $Debugging
)

# Because these are set once in a script scope (all code executed in a module is
# considered to be in one script scope) they will be effective in every function
# and won't override or be overridden by changes in the caller's scope.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Constrained endpoint compatibility
Set-Alias -Name Exit-PSSession -Value Microsoft.PowerShell.Core\Exit-PSSession
Set-Alias -Name Get-Command -Value Microsoft.PowerShell.Core\Get-Command
Set-Alias -Name Get-FormatData -Value Microsoft.PowerShell.Utility\Get-FormatData
Set-Alias -Name Get-Help -Value Microsoft.PowerShell.Core\Get-Help
Set-Alias -Name Measure-Object -Value Microsoft.PowerShell.Utility\Measure-Object
Set-Alias -Name Out-Default -Value Microsoft.PowerShell.Core\Out-Default
Set-Alias -Name Select-Object -Value Microsoft.PowerShell.Utility\Select-Object

if ($Debugging) {
    foreach ($fileName in (Get-ChildItem $PSScriptRoot "*-*.ps1" -Recurse -Exclude "*.Steps.ps1", "*.Tests.ps1", "*.ps1xml")) {
        try {
            Write-Verbose "Loading function from path '$fileName'."
            . $fileName.FullName
        } catch {
            Write-Verbose "Loading function from path '$fileName'."
            Write-Error $_
        }
    }
} else {
    $scriptBlock = Get-ChildItem $PSScriptRoot "*-*.ps1" -Recurse -Exclude "*.Steps.ps1", "*.Tests.ps1", "*.ps1xml" | ForEach-Object {
        Write-Verbose "Loading function from path '$($_.FullName)'."
        [System.IO.File]::ReadAllText($_.FullName)
    }
    $ExecutionContext.InvokeCommand.InvokeScript($false, [scriptblock]::Create($scriptBlock), $null, $null)
}
