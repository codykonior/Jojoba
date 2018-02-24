<#

.SYNOPSIS
Parallel processing with test case output and Jenkins integration.

.DESCRIPTION
For a Jojoba template function this will be the main call in the process {} block. All processing should occur within here.

.PARAMETER ScriptBlock
The test to carry out. It must use $InputObject or $_.

.INPUTS
All inputs aside from the ScriptBlock are taken from the calling function.
    $argument.Batch
    $argument.Callback (optional, for writing events elsewhere)
    $argument.Jenkins (optional, for forcing a write of XML)
    $argument.Throttle (required for batch runs, optional for testing)
    $argument.Suite (optional)

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
        $argument = Get-JojobaArgument $PSCmdlet

        if (!$argument.Throttle -or !$argument.ClassName) {
            #region Direct run
            Write-Verbose "Starting inside thread for $($argument.Name)"

            # Fill out the base test case, named after parts of the original caller
            $jojobaTestCase = [PSCustomObject] @{
                UserName  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                Suite     = $argument.Suite
                Timestamp = Get-Date
                Time      = 0
                ClassName = $argument.ClassName
                Name      = $argument.Name
                Result    = "Pass"
                Message   = New-Object Collections.ArrayList
                Data      = New-Object Collections.ArrayList
            }
            $jojobaAbort = [PSCustomObject] @{
                Message = New-Object Collections.ArrayList
            }

            $jojobaMessages = try {
                &$ScriptBlock *>&1
            } catch {
                # Handle an uncaught stop as a test block failure. This saves
                # having to write test code for everything if the exception is
                # self explanatory
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
                    [void] $jojobaTestCase.Data.Add(($jojobaMessage | Format-List | Out-String))
                }
            }

            # Calculate other useful information for the test case for use by Jenkins
            $jojobaTestCase.Time = ((Get-Date) - $jojobaTestCase.Timestamp).TotalSeconds

            # Write out the test case after getting rid of {} marks
            $jojobaTestCase.Message = $jojobaTestCase.Message -join [Environment]::NewLine
            $jojobaTestCase.Data = $jojobaTestCase.Data -join [Environment]::NewLine

            if (!$jojobaAbort.Message) {
                $jojobaTestCase | Select-Object UserName, Suite, Timestamp, Time, ClassName, Name, Result, Message, Data
            } else {
                Write-Error ($jojobaAbort.Message -join [Environment]::NewLine)
            }
            #endregion
        } else {
            #region Parallel run
            # These are arguments which will be splatted for use by PoshRSJob
            $jobArguments = @{
                Name            = $argument.ClassName
                Throttle        = $argument.Throttle
                Batch           = $argument.Batch
                ModulesToImport = $argument.Suite
                FunctionsToLoad = if (!$argument.Suite) {
                    $argument.ClassName
                } else {
                    $null
                }
                ScriptBlock     = [scriptblock]::Create("`$_ | $($argument.ClassName) -JojobaThrottle 0")
                Verbose         = $VerbosePreference
            }

            # Add any extra switches and parameters to the scriptblock so they can be passed to the caller.
            # This can't handle complex objects - those should be piped in instead.
            # Some exceptions for Jojoba flags are included.
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                if ($_.Key -ne $argument.InputName -and $_.Key -notlike "Jojoba*" -and $_.Key -ne $argument.ArgumentName) {
                    if ($_.Value -is [System.Management.Automation.SwitchParameter]) {
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
                    $PSCmdlet.GetVariableValue($argument.InputName)
                }) | Start-RSJob @jobArguments
            #endregion
        }
    }

    end {
    }
}
