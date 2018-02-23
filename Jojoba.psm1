[CmdletBinding()]
param(
)

# Because these are set once in a script scope (modules and functions are all considered in one script scope)
# they will be effective in every function, and won't override or be overridden by changes in parent scopes.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Get-ChildItem $PSScriptRoot -Recurse -PipelineVariable file | Where-Object { $file.FullName -match "^[^\.]+-[^\.]+\.ps1$" } | ForEach-Object {
    try {
        Write-Verbose "Loading function from path '$($file.FullName)'."
        . $file.FullName
    } catch {
        Write-Error "Failed to load $($file.FullName): $_"
    }
}
