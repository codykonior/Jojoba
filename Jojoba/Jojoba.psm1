[CmdletBinding()]
param(
)

# Because these are set once in a script scope (all code executed in a module is
# considered to be in one script scope) they will be effective in every function
# and won't override or be overridden by changes in the caller's scope.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Get-ChildItem $PSScriptRoot | Get-ChildItem -Recurse -PipelineVariable file | Where-Object { $file.Name -match "^[^\.]+-[^\.]+\.ps1$" } | ForEach-Object {
    try {
        Write-Verbose "Loading function from path '$($file.FullName)'."
        . $file.FullName
    } catch {
        Write-Error "Failed to load $($file.FullName): $_"
    }
}
