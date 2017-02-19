<#

.SYNOPSIS
Parallel processing with test case output and Jenkins integration.

.DESCRIPTION
For a Jojoba template function this will be the main call in the process {} block. All processing should occur within here. 

.PARAMETER ScriptBlock
The test to carry out. It must use $InputObject or $_.

.INPUTS
All inputs aside from the ScriptBlock are taken from the calling function.
    $JojobaBatch
    $JojobaCallback (optional, for writing events elsewhere)
    $JojobaJenkins
    $JojobaThrottle (required for batch runs, optional for testing)
    $JojobaSuite (optional)

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
        # Gather information about the caller
        $jojobaModuleName = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.ModuleName
        $jojobaClassName = $PSCmdlet.GetVariableValue("MyInvocation").MyCommand.Name
        $jojobaName = $PSCmdlet.GetVariableValue("InputObject")
        if ($jojobaClassNameFolder = $PSCmdlet.GetVariableValue("PSCommandPath")) {
            $jojobaClassNameFolder = Split-Path -Leaf (Split-Path -Parent $jojobaClassNameFolder)
        } 
    
        # Inherit Jojoba parameters from the caller
        $JojobaBatch = $PSCmdlet.GetVariableValue("JojobaBatch")
        if (!($JojobaCallback = $PSCmdlet.GetVariableValue("JojobaCallback"))) {
            $JojobaCallback = "Write-JojobaCallback"
        }
        $JojobaJenkins = $PSCmdlet.GetVariableValue("JojobaJenkins")
        if (!($JojobaSuite = $PSCmdlet.GetVariableValue("JojobaSuite"))) {
            if ($JojobaSuite = $jojobaModuleName) {
                if ($jojobaClassNameFolder -and $jojobaClassNameFolder -ne $jojobaModuleName) {
                    $JojobaSuite += "\$jojobaClassNameFolder"
                }
            } else {
                $JojobaSuite = "(Root)"
            }
        }
        $JojobaThrottle = $PSCmdlet.GetVariableValue("JojobaThrottle")
        # You'd almost always specify JojobaThrottle. If you didn't, well, it's allowed, but 
        if ($JojobaThrottle -and !$JojobaBatch) {
            Write-Error "When running in PoshRSJob mode the caller must have a unique `$JojobaBatch per pipeline"
        }
        if (!$JojobaThrottle -and $JojobaJenkins) {
            Write-Error "When running in direct mode the caller cannot use `$JojojobaJenkins"
        }

        if (!$JojobaThrottle) {
            #region Direct run
            Write-Verbose "Starting inside thread for $JojobaName"
            
            # Fill out the base test case, named after parts of the original caller
            $jojobaTestCase = [PSCustomObject] @{
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
            $jojobaTestCase.Time = ((Get-Date) - $jojobaTestCase.Timestamp).TotalSeconds
            
            # If the calling function has a Write-Jojoba then send them a copy of the test. If this fails,
            # it also makes the test fail and which is at least output somewhere.
            if ($jojobaCallbackReference = Get-Command -Module $JojobaModuleName | Where-Object { $_.Name -eq $JojobaCallback }) {
                try {
                    &$jojobaCallbackReference $jojobaTestCase
                } catch {
                    Write-JojobaFail $_.ToString()
                    Write-JojobaData (Resolve-Error $_ -AsString)
                }
            }

            # Write out the test case after getting rid of {} marks
            $jojobaTestCase.Message = $jojobaTestCase.Message -join [Environment]::NewLine
            $jojobaTestCase.Data = $jojobaTestCase.Data -join [Environment]::NewLine
            $jojobaTestCase
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
                Verbose = $VerbosePreference
            }

            # Add any extra switches and parameters to the scriptblock so they can be passed to the caller.
            # This can't handle complex objects - those should be piped in instead.
            # Some exceptions for Jojoba flags are included.            
            $PSCmdlet.GetVariableValue("MyInvocation").BoundParameters.GetEnumerator() | ForEach-Object {
                if (@("InputObject", "JojobaBatch", "JojobaJenkins", "JojobaThrottle") -notcontains $_.Key) {
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
