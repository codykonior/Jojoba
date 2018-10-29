function Test-Array {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover,

        $SomeArray
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Array $SomeArray"
        }
    }
    end {
        Publish-Jojoba
    }
}
