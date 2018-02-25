function Test-String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("InputObject")]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover,

        [string] $SomeString
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "String $SomeString"
        }
    }
    end {
        Publish-Jojoba
    }
}
