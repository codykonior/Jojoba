<#

.SYNOPSIS
Include a custom property on the Jojoba test object.

.DESCRIPTION
Include a custom property on the Jojoba test object.

.PARAMETER Property
A hashtable, such as @{ CategoryName = 'Development' }

.EXAMPLE
Write-JojobaProperty @{ CategoryName = 'Development' }

This doesn't output the property as part of the test case, but when Jojoba calls any
existing callback function, this property will be included in the object passed.

This is so you can write custom data in addition to tests to a database.

#>

function Write-JojobaProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable] $Property
    )

    begin {
    }

    process {
        foreach ($thisProperty in $Property.Keys) {
            if ($jojobaTestCase.psobject.Properties[$thisProperty]) {
                $jojobaTestCase[$thisProperty] = $Property[$thisProperty]
            } else {
                $jojobaTestCase | Add-Member -MemberType NoteProperty -Name $thisProperty -Value $Property[$thisProperty]
            }
        }
    }

    end {
    }
}
