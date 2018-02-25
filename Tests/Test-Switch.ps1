function Test-Switch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("InputObject")]
        $SomeParameter,
        [Parameter(ValueFromRemainingArguments)]
        $SomethingLeftover,
        [switch] $SomeSwitch
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Switch $SomeSwitch"
        }
    }
    end {
        Publish-Jojoba
    }
}
