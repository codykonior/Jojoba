function Test-CriticalFailure {
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
            Write-Output "CriticalFailure $SomeParameter"
            Write-JojobaFail "CriticalFailure because of $SomeParameter" -CriticalFailure
        }
    }
    end {
        Publish-Jojoba
    }
}
