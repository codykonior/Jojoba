function Test-Fail {
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
            Write-JojobaFail "Fail because of $SomeParameter"
        }
    }
    end {
        Publish-Jojoba
    }
}
