<#

.SYNOPSIS
Mark a Jojoba test as aborted.

.DESCRIPTION
This is a hard failure where you don't want to or can't return a test result at all.

.PARAMETER Message
A string. This should be a simple, short sentence, detailing exactly what has failed. Multiple failures will have their messages combined with newlines. A message must be given as it's good pracice. Keep more verbose information for the data block.

.EXAMPLE
Write-JojobaAbort "Job 1 aborted"
Write-JojobaAbort "Job 2 aborted"

This will return the error only.

#>

function Write-JojobaAbort {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    begin {
    }

    process {
        [void] $jojobaAbort.Message.Add($Message)
        Write-Error $Message
    }

    end {
    }
}
