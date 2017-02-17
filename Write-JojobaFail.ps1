<#

.SYNOPSIS
Mark a Jojoba test as failed.

.DESCRIPTION
Jojoba tests pass by default, but they can fail, or be skipped.

.PARAMETER Message
A string. This should be a simple, short sentence, detailing exactly what has failed. Multiple failures will have their messages combined with newlines. A message must be given as it's good pracice. Keep more verbose information for the data block.

.EXAMPLE
Write-JojobaFail "Job 1 failed"
Write-JojobaFail "Job 2 failed"

This will set a Jojoba test case result to "Fail" and popluates the failure reason as:
Job 1 failed
Job 2 failed

#>

function Write-JojobaFail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    begin {
    }

    process {
        [void] $jojoba.Message.Add($Message)

        $jojoba.Result = "Fail"
    }

    end {
    }
}
