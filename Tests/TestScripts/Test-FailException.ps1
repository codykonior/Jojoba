function Test-FailException {
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
            Write-Output "Fail $SomeParameter"
            throw "Fail because of $SomeParameter"
        }
    }
    end {
        Publish-Jojoba
    }
}
