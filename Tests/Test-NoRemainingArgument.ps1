function Test-NoRemainingArgument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject,
        [switch] $JojobaQuiet
    )

    begin {
    }
    process {
        Start-Jojoba {
            Write-Output "Pass $InputObject"
        }
    }
    end {
        Publish-Jojoba
    }
}
