<#

.SYNOPSIS
Parallel processing with test case output and Jenkins integration.

.DESCRIPTION
For a Jojoba template function this will be the main call in the process {} block. All processing should occur within here.

.PARAMETER ScriptBlock
The test to carry out. It must use $InputObject or $_.

.INPUTS
All inputs aside from the ScriptBlock are taken from the calling function.
    $settings.Batch
    $settings.Callback (optional, for writing events elsewhere)
    $settings.Jenkins (optional, for forcing a write of XML)
    $settings.Throttle (required for batch runs, optional for testing)
    $settings.Suite (optional)

.OUTPUTS
A test case object.

#>

function Start-Jojoba {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock] $ScriptBlock,

        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
    }

    process {
        $settings = Get-JojobaArgument $PSCmdlet

        if (!$settings.Throttle) {
            #region Direct run
            Write-Verbose "Starting inside thread for $($settings.Name)"

            # Fill out the base test case, named after parts of the original caller
            $jojobaTestCase = [PSCustomObject] @{
                UserName        = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                Suite           = $settings.Suite
                Timestamp       = Get-Date
                Time            = 0
                ClassName       = $settings.ClassName
                Name            = $settings.Name
                Result          = "Pass"
                Message         = New-Object Collections.ArrayList
                Data            = New-Object Collections.ArrayList
                CriticalFailure = $false
                Other           = $($settings | Format-List | Out-String)
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
                    [void] $jojobaTestCase.Data.Add(($jojobaMessage | Format-List | Out-String))
                }
            }

            # Calculate other useful information for the test case for use by Jenkins
            $jojobaTestCase.Time = ((Get-Date) - $jojobaTestCase.Timestamp).TotalSeconds

            # Write out the test case after getting rid of {} marks
            $jojobaTestCase.Message = $jojobaTestCase.Message -join [Environment]::NewLine
            $jojobaTestCase.Data = $jojobaTestCase.Data -join [Environment]::NewLine

            $jojobaTestCase
            #endregion
        } else {
            #region Parallel run
            # These are arguments which will be splatted for use by PoshRSJob
            $jobArguments = @{
                Name            = $settings.Function
                Throttle        = $settings.Throttle
                Batch           = $settings.Batch
                ModulesToImport = $settings.Suite
                FunctionsToLoad = if (!$settings.Module) {
                    $settings.Function
                } else {
                    $null
                }
                ScriptBlock     = [scriptblock]::Create("`$_ | $($settings.Function) -JojobaThrottle 0")
                Verbose         = $VerbosePreference
            }

            # Add any extra switches and parameters to the scriptblock so they can be passed to the caller.
            # This can't handle complex objects - those should be piped in instead.
            # Some exceptions for Jojoba flags are included.
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                # This is passed by the pipeline
                if ($_.Key -ne $settings.InputName) {
                    if ($_.Key -eq $settings.ArgumentName) {
                        $_.Value | ForEach-Object {
                            if ($_ -eq "-JojobaThrottle") {
                                $_ = "-JojobaThrottleOld"
                            }
                            $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) $_")
                        }
                    } elseif ($_.Value -is [System.Management.Automation.SwitchParameter]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key):`$$($_.Value)")
                    } elseif ($_.Value -is [string]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) '$($_.Value.Replace("'", "''"))'")
                    } else {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) $($_.Value)")
                    }
                }
            }

            Write-Verbose "Scheduling $($jobArguments.Name) batch $($jobArguments.Batch) throttle $($jobArguments.Throttle) modules $($jobArguments.ModulesToImport) functions $($jobArguments.FunctionsToLoad) script $($jobArguments.ScriptBlock)"
            # Here we can continue to pipe in a complex object, or, revert back to the InputObject, for simplicity
            $null = @(if ($PSCmdlet.GetVariableValue("_") -and $PSCmdlet.GetVariableValue("_") -isnot [string]) {
                    $PSCmdlet.GetVariableValue("_")
                } else {
                    $PSCmdlet.GetVariableValue($settings.InputName)
                }) | Start-RSJob @jobArguments
            #endregion
        }
    }

    end {
    }
}
