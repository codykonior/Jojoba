[CmdletBinding()]
param (
    [bool] $Debugging
)

# Because these are set once in a script scope (all code executed in a module is
# considered to be in one script scope) they will be effective in every function
# and won't override or be overridden by changes in the caller's scope.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
