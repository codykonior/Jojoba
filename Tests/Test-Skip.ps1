function Test-Skip {
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
            Write-Output "Skip $SomeParameter"
            Write-JojobaSkip "Skip because of $SomeParameter"
        }
    }
    end {
        Publish-Jojoba
    }
}
