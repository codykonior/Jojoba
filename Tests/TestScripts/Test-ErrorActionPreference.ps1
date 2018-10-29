function Test-ErrorActionPreference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Error $ErrorActionPreference
        }
    }
    end {
        Publish-Jojoba
    }
}
