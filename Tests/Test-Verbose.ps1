function Test-Verbose {
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
            Write-Verbose "Pass $SomeParameter"
        }
    }
    end {
        Publish-Jojoba
    }
}
