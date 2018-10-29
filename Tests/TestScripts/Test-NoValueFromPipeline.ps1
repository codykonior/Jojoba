function Test-NoValueFromPipeline {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
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
