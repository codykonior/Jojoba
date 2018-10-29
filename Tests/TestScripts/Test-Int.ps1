function Test-Int {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover,

        [int] $SomeInt
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Int $SomeInt"
        }
    }
    end {
        Publish-Jojoba
    }
}
