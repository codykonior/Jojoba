function Test-Property {
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
            Write-JojobaProperty @{ OtherProperty = "Set" }
        }
    }
    end {
        Publish-Jojoba
    }
}
