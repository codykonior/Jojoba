<#

.SYNOPSIS
Retrieve results from Jojoba parallel runs and optionally package them for Jenkins.

.DESCRIPTION
For a Jojoba template function a call to Publish-Jojoba must be in the end {} block. If parallel processing has been used, this script will wait for all jobs to complete before outputting the test data. It may also write a Jojoba.xml for processing by Jenkins.

.PARAMETER OutputPath
Output path for Jojoba XML. This is only triggered if JojobaThrottle -ne 0, $JojobaJenkins = $true, or it is executing under Jenkins.

.INPUTS
None. All inputs are taken from the calling function ($JojobaBatch, $JojobaJenkins, and $JojobaThrottle).

.OUTPUTS
Test case data from all processed jobs. If a job fails, which should not happen, its output will be returned also.

Throttle
Batch
Jenkins
Passthru

#>

function Publish-Jojoba {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "global:LASTEXITCODE", Justification = "Required for Jenkins")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "failed", Justification = "Bug in Analyzer")]
    param (
    )

    begin {
        $settings = Get-JojobaArgument $PSCmdlet
        $jobs = New-Object Collections.ArrayList
        $failed = $false
    }

    process {
        #region Retrieve and clean up results if run in parallel mode
        if ($settings.Throttle) {
            $newJobs = New-Object Collections.ArrayList

            # Get, receive, and remove jobs as they complete. Any errors should be caught
            # and encapsulated as part of a test result. But in case they don't, then we
            # deal with them separately.
            Get-RSJob -Batch $settings.Batch | Wait-RSJob -ShowProgress | ForEach-Object {
                $jobResult = Receive-RSJob $_

                if ($_.State -eq "Failed" -or $_.HasErrors -or ($jobResult -and $jobResult.psobject.Properties["CriticalFailure"] -and $jobResult.CriticalFailure)) {
                    $failed = $true
                }

                [void] $jobs.Add($jobResult)
                [void] $newJobs.Add($jobResult)

                # Write out all the good test information
                if (!$settings.Quiet) {
                    $jobResult | Select-Object UserName, Suite, Timestamp, Time, ClassName, Name, Result, Message, Data | Format-List | Out-String -Stream -PipelineVariable line | ForEach-Object {
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
                }

                $_
            } | Remove-RSJob

            if ($settings.PassThru -and $newJobs) {
                $newJobs
            }
        }
        #endregion
    }

    end {
        if ($settings.Jenkins -and $jobs) {
            Write-JojobaXml $jobs -OutputPath $settings.Jenkins
        }

        if ($failed) {
            $global:LASTEXITCODE = 1
            Write-Error "One or more tasks indicated a Critical Failure"
        } else {
            $global:LASTEXITCODE = 0
        }
    }
}
