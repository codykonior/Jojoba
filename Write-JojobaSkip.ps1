<#

.SYNOPSIS
Mark a Jojoba test as skipped.

.DESCRIPTION
Jojoba tests pass by default, but they can fail, or be skipped.

.PARAMETER Message
A string. This should be a simple, short sentence, detailing exactly what has been skipped or why. Multiple skips will have their messages combined with newlines. A message must be given as it's good pracice. Keep more verbose information for the data block.

.EXAMPLE
Write-JojobaSkip "Server skipped because it is turned off"

This will set a Jojoba test case result to "Skip" and popluates the skip reason as:
Server skipped because it is turned off

.NOTES
A test would normally be skipped if the test cannot or should not be run - for example if the test result would not be valid. 

It should only be used if the test result requires no further action. If action was required, this test should be marked as a fail.

#>

function Write-JojobaSkip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )

    begin {
    }

    process {
        [void] $jojobaTestCase.Message.Add($Message)
        $jojobaTestCase.Result = "Skip"
    }

    end {
    }
}
