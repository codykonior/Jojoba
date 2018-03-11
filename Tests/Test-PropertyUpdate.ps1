function Test-PropertyUpdate {
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
            Write-JojobaProperty @{ OtherProperty = "Set" }
            Write-JojobaProperty @{ OtherProperty = "Update" }
        }
    }
    end {
        Publish-Jojoba
    }
}
