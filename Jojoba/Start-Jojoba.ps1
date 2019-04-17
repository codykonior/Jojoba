<#

.SYNOPSIS
Creates a job for each incoming pipeline object and captures the output into a
test case object.

.DESCRIPTION
Start-Jojoba is used in the process {} block of a function that uses Jojoba.
It should wrap all the code within that block.

.PARAMETER ScriptBlock
This is the logic to carry out.

.INPUTS
All inputs aside from the ScriptBlock are taken from the calling function.

.OUTPUTS
A test case object.

#>

function Start-Jojoba {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [scriptblock] $ScriptBlock,

        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
    }

    process {
        $configuration = Get-JojobaConfiguration $PSCmdlet

        if (!$configuration.Throttle) {
            #region Direct run
            Write-Verbose "Starting inside thread for $($configuration.Name)"

            # Fill out the test case
            $jojobaTestCase = [PSCustomObject] @{
                UserName        = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                Timestamp       = (Get-Date).ToUniversalTime()
                Time            = 0
                CriticalFailure = $false
                #
                Suite           = $configuration.Suite
                ClassName       = $configuration.ClassName
                Name            = $configuration.Name
                Result          = "Pass"
                Message         = New-Object Collections.ArrayList
                Data            = New-Object Collections.ArrayList
            }

            $jojobaMessages = try {
                &$ScriptBlock *>&1
            } catch {
                # Handle an uncaught stop as a test block failure. This saves
                # having to write test code for everything if the exception is
                # self explanatory
                # This isn't a Critical Failure though.
                Write-JojobaFail $_.ToString()
            }

            foreach ($jojobaMessage in ($jojobaMessages | Where-Object { $null -ne $_ })) {
                if ($jojobaMessage -is [string]) {
                    [void] $jojobaTestCase.Data.Add($jojobaMessage)
                } elseif ($jojobaMessage.GetType().FullName -eq "System.Management.Automation.InformationRecord") {
                    # Used in PS5 to capture Write-Host output
                    if ($jojobaMessage.Tags.Contains("PSHOST")) {
                        [void] $jojobaTestCase.Data.Add($jojobaMessage)
                    } else {
                        [void] $jojobaTestCase.Data.Add($jojobaMessage)
                    }
                } elseif ($jojobaMessage -is [System.Management.Automation.VerboseRecord]) {
                    [void] $jojobaTestCase.Data.Add("VERBOSE: $jojobaMessage")
                } elseif ($jojobaMessage -is [System.Management.Automation.WarningRecord]) {
                    [void] $jojobaTestCase.Data.Add("WARNING: $jojobaMessage")
                } elseif ($jojobaMessage -is [System.Management.Automation.ErrorRecord]) {
                    # Exceptions also get wrapped in an ErrorRecord
                    [void] $jojobaTestCase.Data.Add($jojobaMessage)
                } else {
                    # Expand complex objects
                    $outStringParams = $configuration.OutString
                    [void] $jojobaTestCase.Data.Add(($jojobaMessage | Format-List | Out-String @outStringParams | ForEach-Object {
                                $_ -replace "(?m)\A\s+", "" -replace "(?m)^\s(\s+)\Z", "" }))
                }
            }

            # Calculate other useful information for the test case for use by Jenkins
            $jojobaTestCase.Time = ((Get-Date).ToUniversalTime() - $jojobaTestCase.Timestamp).TotalSeconds

            # Write out the test case after getting rid of {} marks
            $jojobaTestCase.Message = (($jojobaTestCase.Message -join [Environment]::NewLine), $null, 1 -ne "")[0]
            $jojobaTestCase.Data = (($jojobaTestCase.Data -join [Environment]::NewLine), $null, 1 -ne "")[0]

            $jojobaTestCase
            #endregion
        } else {
            #region Parallel run
            # These are arguments which will be splatted for use by PoshRSJob
            $jobArguments = @{
                Name            = $configuration.Function
                Throttle        = $configuration.Throttle
                Batch           = $configuration.Batch
                ModulesToImport = $configuration.Suite
                FunctionsToLoad = if (!$configuration.Module) {
                    $configuration.Function
                } else {
                    $null
                }
                Verbose         = $configuration.Verbose
            }
            $jobScriptBlock = "Import-Module Jojoba -Verbose:`$false; `$_ | $($configuration.Function) -JojobaThrottle 0"
            if (!$configuration.Unsafe) {
                $jobScriptBlock = "Set-StrictMode -Version Latest; `$ErrorActionPreference = `"Stop`"; $jobScriptBlock"
            }
            $jobArguments.ScriptBlock = [scriptblock]::Create($jobScriptBlock)

            # Add any extra switches and parameters to the scriptblock so they
            # can be passed to the caller. This can't handle complex objects -
            # those should be piped in instead.
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                # The main pipeline object is skipped here because it is passed
                # in via the pipeline
                if ($_.Key -ne $configuration.InputName) {
                    # Jojoba arguments are an array that is copied as-is, except
                    # for JojobaThrottle, as this is called with a 0 to run the
                    # actual code once it has been boxed into jobs
                    if ($_.Key -eq $configuration.ArgumentName) {
                        $_.Value | ForEach-Object {
                            if ($_ -eq "-JojobaThrottle") {
                                $_ = "-JojobaThrottleOld"
                            }
                            $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) $_")
                        }
                    } elseif ($_.Value -is [System.Management.Automation.SwitchParameter]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key):`$$($_.Value)")
                    } elseif ($_.Value -is [bool]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) `$$($_.Value)")
                    } elseif ($_.Value -is [string]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) '$($_.Value.Replace("'", "''"))'")
                    } elseif ($_.Value -is [array]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) $(($_.Value | ForEach-Object { "'$($_.ToString().Replace("'", "''"))'" }) -join ",")")
                    } else {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) $($_.Value)")
                    }
                }
            }

            Write-Verbose "Scheduling $($jobArguments.Name) batch $($jobArguments.Batch) throttle $($jobArguments.Throttle) modules $($jobArguments.ModulesToImport) functions $($jobArguments.FunctionsToLoad) script $($jobArguments.ScriptBlock)"

            # If the function was called with a pipeline (it should have been)
            # then pass that on in the pipeline.
            # Otherwise pass the variable in over the pipeline anyway, as it's
            # the same thing.
            $null = @(if ($PSCmdlet.GetVariableValue("_") -and $PSCmdlet.GetVariableValue("_") -isnot [string]) {
                    $PSCmdlet.GetVariableValue("_")
                } else {
                    $PSCmdlet.GetVariableValue($configuration.InputName)
                }) | Start-RSJob @jobArguments
            #endregion
        }
    }

    end {
    }
}
