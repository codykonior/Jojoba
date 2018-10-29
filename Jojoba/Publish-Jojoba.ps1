<#

.SYNOPSIS
Receives output from RSJobs, does clean-up, outputs test results, and flags any
critical failures.

.DESCRIPTION
Jojoba requires that functions have an end {} block that calls Publish-Jojoba.
If parallel processing was used, this script waits for each to complete, and
receives the test data. Test data is output to the screen, or to the pipeline,
and optionally to a JUnit XML file for Jenkins.

If the test data indicates a critical failure then $global:LASTEXITCODE is set
to 1 (failure) and a Write-Error is done after all test results are output.

#>

function Publish-Jojoba {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', 'global:LASTEXITCODE', Justification = 'Required for Jenkins')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'failed', Justification = 'Bug in Analyzer')]
    param (
        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
        $configuration = Get-JojobaConfiguration $PSCmdlet
        $jobResults = New-Object Collections.ArrayList
        $failed = $false
    }

    process {
        #region Retrieve and clean up results if run in parallel mode
        if ($configuration.Throttle) {
            # Get, receive, and remove jobs as they complete. Any errors should be caught
            # and encapsulated as part of a test result. But in case they don't, then we
            # deal with them separately.
            Get-RSJob -Batch $configuration.Batch | Wait-RSJob -ShowProgress | ForEach-Object {
                $jobResult = Receive-RSJob $_
                if ($_.State -eq "Failed" -or $_.HasErrors -or ($jobResult -and $jobResult.psobject.Properties["CriticalFailure"] -and $jobResult.CriticalFailure)) {
                    $failed = $true
                }
                Remove-RSJob $_

                [void] $jobResults.Add($jobResult)

                # Write out all the good test information
                if (!$configuration.Quiet) {
                    $jobResult | Select-Object UserName, Suite, Timestamp, Time, ClassName, Name, Result, Message, Data | Format-List | Out-String | ForEach-Object -PipelineVariable line {
                        $_ -replace "(?m)\A\s+", "" -replace "(?m)^\s(\s+)\Z", "" -split [Environment]::NewLine
                    } | ForEach-Object {
                        if ($line -match "^(Name.*?:)(.*)`$") {
                            Write-Host $Matches[1] -NoNewline -ForegroundColor DarkGray
                            Write-Host $Matches[2] -ForegroundColor White
                        } elseif ($line -match "^(Result.*)(Pass)`$") {
                            Write-Host $Matches[1] -NoNewline -ForegroundColor DarkGray
                            Write-Host $Matches[2] -ForegroundColor Green
                        } elseif ($line -match "^(Result.*)(Fail)`$") {
                            Write-Host $Matches[1] -NoNewline -ForegroundColor DarkGray
                            Write-Host $Matches[2] -ForegroundColor Red
                        } else {
                            Write-Host $line -ForegroundColor DarkGray
                        }
                    }
                #>
                }

                if ($configuration.PassThru) {
                    $jobResult
                }

                if ($configuration.Callback) {
                    try {
                        &($configuration.CallBack) $jobResult
                    } catch {
                        Write-Warning "Jojoba - Callback to $($configuration.Callback) failed: $_"
                    }
                }
            }
        }
        #endregion
    }

    end {
        if ($configuration.Jenkins -and $jobResults) {
            Write-JojobaXml $jobResults -OutputPath $configuration.Jenkins
        }

        if ($failed) {
            $global:LASTEXITCODE = 1
            Write-Error "One or more tasks indicated a Critical Failure"
        } else {
            $global:LASTEXITCODE = 0
        }
    }
}
