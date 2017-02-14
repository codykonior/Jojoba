# PowerShell: Jojoba module

## TOPIC
    about_Jojoba

## SHORT DESCRIPTION
    Jojoba provides a simple domain-specific language to add to functions. This wraps the
    functions so that they can return a consistent result format, automatically run in
    parallel, and write Jenkins XML output.
    
## LONG DESCRIPTION
	Functions use Jojoba at set integration points.
	
	* They take some set parameters.
		$InputObject to refer to a specific instance of something being tested.
		$Jenkins to enable or disable writing Jenkins jUnit XML to disk.
		$Parallel to enable or disable parallelism. By default it's enabled. It's useful
			to disable this during debugging, as it allows you to set easy breakpoints
			in PowerShell ISE in your script block; otherwise those will be run in other
			threads and likely won't trigger.
		$JojobaThrottle to set a thread count, defaults to CPU count.
		$JojobaBatch which is used internally for thread pooling.
		
	* They call Start-Jojoba in their process block.
		It takes a scriptblock, which is just a normal script block to do any kind of
		operations on $InputObject and other defined parameters.
		
	* They notify Jojoba of any test-specific information.
		Write-JojobaData to output generic verbose data and stack traces.
		Write-JojobaFail to fail the test with a message.
		Write-JojobaSkip to skip the test with a message.
		
	* They call Publish-Jojoba in their end block.

## REQUIREMENTS
	Functions must exist inside a module, as the module name is used to set the suite name
	for a test. That module must require the Jojoba module.
	
	Functions must use an $InputObject string. This is used to give a case name to the
	test. It's okay and recommended to alias this field. Common examples would be:
		ComputerName
		ServerInstance
		Url
		
	However it's also acceptable to pipeline complex object input into the test if it has
	an InputObject or other aliased property name. These will be passed on as expected.

	These modules should be available:	
		Error
		PoshRSJob
	
	It's also recommended that you use CimSession and DbData modules as these are more 
	reliable when run concurrently (compared to WMI and Invoke-Sqlcmd).
	
## EXAMPLE #1
	Functions should follow this strict template. It's okay to add extra parameters, they
	will be passed onto as expected.

	function Test-TestName {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
			[string] $InputObject,

			[switch] $Jenkins,
			[switch] $Parallel = $true,
			[int]   $JojobaThrottle = $env:NUMBER_OF_PROCESSORS,
			[guid]  $JojobaBatch = [System.Guid]::NewGuid().Guid
		)        
		begin {
		}
		process {
			Start-Jojoba {
				<#
				Write-JojobaData "..."
			
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