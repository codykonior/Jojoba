<#

.SYNOPSIS
Retrieve results from Jojoba parallel runs and optionally package them for Jenkins.

.DESCRIPTION
For a Jojoba template function a call to Publish-Jojoba must be in the end {} block. If parallel processing has been used, this script will wait for all jobs to complete before outputting the test data. It may also write a Jojoba.xml for processing by Jenkins.

.INPUTS
None. All inputs are taken from the calling function ($JojobaBatch, $JojobaJenkins, and $JojobaThrottle).

.OUTPUTS
Test case data from all processed jobs. If a job fails, which should not happen, its output will be returned also. 

#>

function Publish-Jojoba {
    [CmdletBinding()]
    param (
    )

    begin {
    }

    process {
        #region Retrieve and clean up results if run in parallel mode
        if ($PSCmdlet.GetVariableValue("JojobaThrottle")) {
            $completedJobs = New-Object Collections.ArrayList
            $jobErrors = New-Object Collections.ArrayList

            # Get, receive, and remove jobs as they complete. Any errors should be caught
            # and encapsulated as part of a test result. But in case they don't, then we
            # deal with them separately.
            Get-RSJob -Batch $PSCmdlet.GetVariableValue("JojobaBatch") | Wait-RSJob | ForEach-Object {
                if ($_.State -ne "Failed" -and !$_.HasErrors) {
                    [void] $completedJobs.Add((Receive-RSJob $_))
                } else {
                    [void] $jobErrors.Add((Receive-RSJob $_))
                }
                
                $_
            } | Remove-RSJob
            
            # Write out the XML file if there's output, and we're either asked or Jenkins is in use
            if ($completedJobs -and ($PSCmdlet.GetVariableValue("JojobaJenkins") -or $env:BUILD_URL)) {
                Write-JojobaXml $completedJobs
            }

            # Write out all the good test information
            if ($completedJobs) {
                $completedJobs
            }
            if ($jobErrors) {
                # Write out any failed information. This will mess up the pipeline, but that's
                # okay, because if this happens then something has gone seriously wrong, and it
                # can show up in the Jenkins build console
                $jobErrors

                # Mark any Jenkins build as failed
                $global:LASTEXITCODE = 1
            } else {
                # Mark the build as a success (though Jenkins may interpret the test results
                # and mark it as failed for other reasons)
                $global:LASTEXITCODE = 0
            }
        }
        #endregion
    }

    end {
    }
}
