# PowerShell: Jojoba module

## TOPIC
    about_Jojoba

## SHORT DESCRIPTION
    Jojoba is a small set of DSL keywords to use in a function template. These
    wrap the function to automatically scale out using PoshRSJob, gather all
    output data to return in a jUnit result format, and optionally write it 
    out to disk in a jUnit XML format that Jenkins can understand.
    
## LONG DESCRIPTION
	Functions use Jojoba at set integration points.
	
	* Your function must define some parameters.
		$InputObject to refer to a specific instance of something being tested.
            To avoid weird errors be careful to declare it EXACTLY as it's done
            in the template (apart from adding other aliases).
		$JojobaBatch which is used internally for pooling the entire pipeline
            into one runspace.
		$JojobaJenkins to enable writing Jenkins jUnit XML to disk. This is
            only required if you need to force it - it can detect Jenkins and
            will always write XML in those cases.
		$JojobaThrottle to set a job count which defaults to CPU count. If 0,
            then the job system is skipped (good for debugging as otherwise a
            runspace job usually won't trigger an ISE breakpoint).
		$JojobaSuite to optionally override the Suite name of a test.

	* Your function calls Start-Jojoba in the process block.
		It takes a scriptblock, which is just a normal script block to do any 
            kind of operations on $InputObject and other defined parameters.
		
	* Your function notifies Jojoba of any test-specific information.
		Write-JojobaFail to fail the test with a message. After this processing
            continues unless you use "return".
		Write-JojobaSkip to skip the test with a message. After this processing
            continues unless you use "return".
        All streams (depending on your version of PowerShell and its preference
            setings) are written to the Data section as if you were running the
            script interactively. Non-terminating errors will be written here
            with a stack dump. Uncaught terminating errors will result in a call
            to Write-JojobaFail (setting the Result to Fail, Message to the
            exception message, and Data to a stack dump). Then your script block
            will terminate.
		
	* Your function calls Publish-Jojoba in the end block. This is required 
        to wait and receive all job results created in the process block.

## REQUIREMENTS
	Functions must exist inside a module, as the module name is used to set the
    suite name for a test (though it can be overridden). That module must 
    require the Jojoba module.
	
	Functions must use an $InputObject string. This is used to give a case name
    to the test. It's okay and recommended to alias this field, but otherwise
    the parameter information and type should remain as-is. Common examples
    would be:
		ComputerName
		ServerInstance
		Url
		
    It's acceptable to pipe into InputObject as a property name, as declared
    in the syntax. It and other bound parameters will be pased on as expected.

	These modules are required as Jojoba has a dependency on them:	
		Error
		PoshRSJob
	
	It's also recommended that you use the Cim and DbData modules as these 
    are more reliable when run concurrently (compared to WMI and Invoke-Sqlcmd).
	
## EXAMPLE #1
	Functions should follow this strict template. It's okay to add extra 
    parameters, they will be passed onto as expected.

	function Test-Template {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
			[string] $InputObject,
            <# ... extra parameters .. #>

			[string] $JojobaBatch = [System.Guid]::NewGuid().ToString(),
			[int]    $JojobaThrottle = $env:NUMBER_OF_PROCESSORS
		)

		begin {
		}

		process {
			Start-Jojoba {
				<#
				Write-JojobaFail "..."
				Write-JojobaSkip "..."
				#>
		   }
		}

		end {
			Publish-Jojoba
		}
	}

## Example 2
	A more complete function. In this case, the suite name can be overridden,
    and your module can use -PassThru to pass the jUnit records to a function 
	which can be written out to a destination in a format of your choosing.
	This is useful to send data to a database alongside XML and Jenkins.

	function Test-Template {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
			[string] $InputObject,
            <# ... extra parameters .. #>

			[string] $JojobaBatch = [System.Guid]::NewGuid().ToString(),
			[switch] $JojobaJenkins,
            [string] $JojobaSuite = "My Suite Name",
			[int]    $JojobaThrottle = $env:NUMBER_OF_PROCESSORS
		)

		begin {
		}

		process {
			Start-Jojoba {
				<#
				Write-JojobaFail "..."
				Write-JojobaSkip "..."
				#>
		   }
		}

		end {
			Publish-Jojoba
		}
	}

## LINKS
    https://github.com/codykonior/Jojoba

[![Build status](https://ci.appveyor.com/api/projects/status/oefdf90a75hqsk69?svg=true)](https://ci.appveyor.com/project/codykonior/jojoba)
