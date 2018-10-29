function Test-Callback {
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
            Write-Output "Pass $SomeParameter"
        }
    }
    end {
        Publish-Jojoba -JojobaCallback "Write-Callback"
    }
}
