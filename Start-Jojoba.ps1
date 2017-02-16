<#

.SYNOPSIS
Parallel processing with test case output and Jenkins integration.

.DESCRIPTION
For a Jojoba template function this will be the main call in the process {} block. All processing should occur within here. 

.PARAMETER ScriptBlock
The test to carry out. It must use $InputObject or $_.

.INPUTS
None. All inputs are taken from the host function ($InputObject, Parallel, $_, $JojobaThrottle, $JojobaBatch).

Other inputs taken are the calling module name and calling function name.

.OUTPUTS
A test case object. 

#>

function Start-Jojoba {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock] $ScriptBlock
    )

    begin {
    }

    process {
        # Fill out the base test case, named after parts of the caller
        $jojoba = [PSCustomObject] @{
            Suite = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.ModuleName
            Timestamp = Get-Date
            Time = 0
            ClassName = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.Name
            Name = $PSCmdlet.GetVariableValue("InputObject")
            Result = "Pass"
            Message = New-Object Collections.ArrayList
            Data = New-Object Collections.ArrayList
        }

        # Determine whether we're going to run the test block, or spawn off copies to run in Parallel
        if (!$PSCmdlet.GetVariableValue("Parallel")) {
            #region Single-threaded run
            Write-Verbose "Starting $($jojoba.Name)"
            
            try {
                 &$ScriptBlock
            } catch {
                # Handle uncaught exceptions as a test block failure. This saves a lot of test code.
                Write-JojobaFail $_.ToString()
                Write-JojobaData (Resolve-Error $_ -AsString)
            }

            # Calculate other useful information for the test case for use by Jenkins
            $jojoba.Time = ((Get-Date) - $jojoba.Timestamp).TotalSeconds

            # Simplify the various outputs
            if ($jojoba.Message) {
                $jojoba.Message = $jojoba.Message -join [Environment]::NewLine
            }
            if ($jojoba.Data) {
                $jojoba.Data = $jojoba.Data -join [Environment]::NewLine
            }

            # Write out the test case
            $jojoba
            #endregion
        } else {
            #region Parallel run
            # These are arguments which will be splatted for use by PoshRSJob
            $jobArguments = @{
                Throttle = $PSCmdlet.GetVariableValue("JojobaThrottle")
                Batch = $PSCmdlet.GetVariableValue("JojobaBatch")
                ModulesToImport = @($jojoba.Suite)
                ScriptBlock = [scriptblock]::Create("`$_ | $($jojoba.ClassName) -Parallel:`$false")
            }

            # Add any extra switches and parameters to the scriptblock so they can be passed to the caller.
            # This can't handle complex objects - those should be piped in instead.
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                if ($_.Key -ne "InputObject") {
                    if ($_.Value -is [System.Management.Automation.SwitchParameter]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key):`$$($_.Value)")
                    } else {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) $($_.Value)")
                    }
                }
            }

            Write-Verbose "Scheduling $($jojoba.Name) as $($jobArguments.ScriptBlock)"
            # Here we can continue to pipe in a complex object, or, revert back to the InputObject, for simplicity
            @(if ($PSCmdlet.GetVariableValue("_") -and $PSCmdlet.GetVariableValue("_") -isnot [string]) { $PSCmdlet.GetVariableValue("_") } else { $PSCmdlet.GetVariableValue("InputObject") }) | Start-RSJob @jobArguments | Out-Null
            #endregion
        }
    }

    end {
    }
}
