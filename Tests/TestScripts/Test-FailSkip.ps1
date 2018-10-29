function Test-FailSkip {
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
            Write-JojobaFail "Broken"
            Write-JojobaSkip "Skip because of $SomeParameter"
        }
    }
    end {
        Publish-Jojoba
    }
}
