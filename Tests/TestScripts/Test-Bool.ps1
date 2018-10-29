function Test-Bool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover,
        [bool] $SomeBool
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Bool $SomeBool"
        }
    }
    end {
        Publish-Jojoba
    }
}
