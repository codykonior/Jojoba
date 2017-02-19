<#

.SYNOPSIS
Parallel processing with test case output and Jenkins integration.

.DESCRIPTION
For a Jojoba template function this will be the main call in the process {} block. All processing should occur within here. 

.PARAMETER ScriptBlock
The test to carry out. It must use $InputObject or $_.

.INPUTS
None. All inputs are taken from the calling function ($JojobaBatch, $JojobaJenkins, $JojobaThrottle). The calling function is also probed for $InputObject and the $_ pipeline.

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
        # Inherit the verbose setting across modules if it wasn't overridden
        $VerbosePreference = $PSCmdlet.GetVariableValue("VerbosePreference")
        # This is not specified, it's for internal use
        $JojobaModuleName = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.ModuleName
        $JojobaClassName = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.Name
        $JojobaName = $PSCmdlet.GetVariableValue("InputObject")
        
        # Inherit the Jojoba specific variables
        $JojobaBatch = $PSCmdlet.GetVariableValue("JojobaBatch")
        if (!($JojobaCallback = $PSCmdlet.GetVariableValue("JojobaCallback"))) {
            $JojobaCallback = "Write-JojobaCallback"
        }
        # Not used here, used in Publish-Jojoba
        # $JojobaJenkins = $PSCmdlet.GetVariableValue("JojobaJenkins")
        # Suite can be overridden, otherwise it's the module name, or just
        # "(Root)" (something is needed to represent it in jUnit).
        if (!($JojobaSuite = $PSCmdlet.GetVariableValue("JojobaSuite"))) {
            if (!($JojobaSuite = $jojobaModuleName)) {
                $JojobaSuite = "(Root)"
            }
        }
        $JojobaThrottle = $PSCmdlet.GetVariableValue("JojobaThrottle")
        
        # If it's not defined, or 0, it's a direct/single run
        if (!$JojobaThrottle) {
            #region Single-threaded run
            Write-Verbose "Starting inside thread for $JojobaName"
            
            # Fill out the base test case, named after parts of the original caller
            $jojoba = [PSCustomObject] @{
                UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                Suite = $JojobaSuite
                Timestamp = Get-Date
                Time = 0
                ClassName = $JojobaClassName
                Name = $JojobaName
                Result = "Pass"
                Message = New-Object Collections.ArrayList
                Data = New-Object Collections.ArrayList
            }

            try {
                &$ScriptBlock
            } catch {
                # Handle uncaught exceptions as a test block failure. This saves a lot of test code.
                Write-JojobaFail $_.ToString()
                Write-JojobaData (Resolve-Error $_ -AsString)
            }

            # Calculate other useful information for the test case for use by Jenkins
            $jojoba.Time = ((Get-Date) - $jojoba.Timestamp).TotalSeconds
            
            # If the calling function has a Write-Jojoba then send them a copy of the test. If this fails,
            # it also makes the test fail and which is at least output somewhere.
            if ($writeJojoba = Get-Command -Module $jojoba.Suite | Where-Object { $_.Name -eq $JojobaCallback }) {
                try {
                    &$writeJojoba $jojoba
                } catch {
                    Write-JojobaFail $_.ToString()
                    Write-JojobaData (Resolve-Error $_ -AsString)
                }
            }

            # Write out the test case after removing ArrayList {} marks
            $jojoba.Message = $jojoba.Message -join [Environment]::NewLine
            $jojoba.Data = $jojoba.Data -join [Environment]::NewLine
            $jojoba
            #endregion
        } else {
            #region Parallel run
            # These are arguments which will be splatted for use by PoshRSJob
            $jobArguments = @{
                Throttle = $JojobaThrottle
                Batch = $JojobaBatch
                ModulesToImport = $JojobaModuleName
                FunctionsToLoad = if (!$jojobaModuleName) { $JojobaClassName } else { $null }
                ScriptBlock = [scriptblock]::Create("`$_ | $($JojobaClassName) -JojobaThrottle 0")
            }

            # Add any extra switches and parameters to the scriptblock so they can be passed to the caller.
            # This can't handle complex objects - those should be piped in instead.
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                if ($_.Key -ne "InputObject" -and $_.Key -ne "JojobaThrottle") {
                    if ($_.Value -is [System.Management.Automation.SwitchParameter]) {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key):`$$($_.Value)")
                    } else {
                        $jobArguments.ScriptBlock = [scriptblock]::Create("$($jobArguments.ScriptBlock) -$($_.Key) $($_.Value)")
                    }
                }
            }

            Write-Verbose "Scheduling $($JojobaName) batch $($JojobaBatch) throttle $($jobArguments.Throttle) modules $($jobArguments.ModulesToImport) functions $($jobArguments.FunctionsToLoad) script $($jobArguments.ScriptBlock)"
            # Here we can continue to pipe in a complex object, or, revert back to the InputObject, for simplicity
            $null = @(if ($PSCmdlet.GetVariableValue("_") -and $PSCmdlet.GetVariableValue("_") -isnot [string]) { $PSCmdlet.GetVariableValue("_") } else { $PSCmdlet.GetVariableValue("InputObject") }) | Start-RSJob @jobArguments
            #endregion
        }
    }

    end {
    }
}
