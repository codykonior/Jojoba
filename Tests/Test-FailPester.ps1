function Test-FailPester {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("InputObject")]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Fail $SomeParameter"
            "ABC" | Should -Be "BCD"
        }
    }
    end {
        Publish-Jojoba
    }
}
