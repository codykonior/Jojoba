<#

.SYNOPSIS
Write output to be stored in a Jojoba test case data block

.DESCRIPTION
Jojoba test cases have a data block which can contain further information. It's often used to contain verbose output, status messages, and stacktraces, which are too long for a simple error message.

.PARAMETER Message
A Message. If it's not a string it will be piped through Format-List and Out-String. This makes it easier to dump verbose objects and have legible output.

.EXAMPLE
[PSCustomObject] @{ComputerName = "Server1"; CategoryName = "Test"; CompanyName = "Safe SQL";} | Write-JojobaData

Write a complex object to the data section of a test. It will be output in the test case as follows:

ComputerName : Server1
CategoryName : Test
CompanyName  : Safe SQL

#>

function Write-JojobaData {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        $Message
    )

    begin {
    }

    process {
        if ($Message) {
            if ($Message -is [string]) {
                [void] $jojoba.Data.Add($Message)
            } else {
                [void] $jojoba.Data.Add(($Message | Format-List | Out-String))
            }
        }
    }

    end {
    }
}
