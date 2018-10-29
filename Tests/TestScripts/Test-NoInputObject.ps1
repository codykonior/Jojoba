function Test-NoInputObject {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        $SomethingOtherThanInputObject,
        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Pass nothing"
        }
    }
    end {
        Publish-Jojoba
    }
}
