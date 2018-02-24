![][1] 

[![Build status](https://ci.appveyor.com/api/projects/status/oefdf90a75hqsk69?svg=true)](https://ci.appveyor.com/project/codykonior/jojoba)

#### Description

Provides a simple method of building parallel capability into PowerShell functions and wrapping results in a unit testing format.

I use it for operational validation of large server environments because it makes it easy to write tests that can run quickly and be understood interactively and by Jenkins.

___Please note: This version is in Alpha and documentation is still being updated.___

#### Download and install Jojoba using PowerShell:

``` powershell
Install-Module -Name Jojoba
```

It is written for Windows PowerShell 5.1 and has also been tested on PowerShell Core 6.0.1 for Windows.

#### Example

Any function using Jojoba needs a minimum of:
* A string type ValueFromPipeline argument with a name or alias of InputObject. This may also have an attribute of ValueFromPipelineByPropertyValue.
* A ValueFromRemainingArguments argument of any name. Any switches for Jojoba will use the -Jojoba prefix.
* `Start-Jojoba {}` wrapping code in the process block.
* `Publish-Jojoba` in the end block.

It's fine for other parameters to be in use as well.

``` powershell
function Test-ComputerPing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias("InputObject")]
        [string] $ComputerName,
        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
    }
    process {
        Start-Jojoba {
            ping $ComputerName -n 1
            if (!$?) {
                Write-JojobaFail "Connection failed"
            }
        }
    }
    end {
        Publish-Jojoba
    }
}
```

### What happens?

* When the pipeline starts a new runspace is created.
* Any pipelined input will be queued into those slots.
* The results are written to the host in a unit test format.
  * Suite = Module
  * Class = Function
  * Name = Pipeline
* Tests will pass by default if no terminating exceptions are thrown.

![][2]

#### What else can I do?

* `Write-JojobaSkip` will mark the output as skipped, for example if some pre-condition is not met.
* `Write-JojobaAbort` will terminate the block with an error which will not be wrapped in the JUnit format. This is rarely needed and generally not a good idea.

#### What options are there?

Parameters are passed to your function through the RemainingArguments variable not to Jojoba directly.

* `-JojobaThrottle` accepts an integer to determine how many jobs will be spun up. It defaults to match the number of CPU cores.
* `-JojobaQuiet` will suppress the Write-Host output.
* `-JojobaPassThru` will return the unit test results as standard objects.
* `-JojobaSuite` can be used to override the Suite name in the output.
* `-JojobaClassName` can be used to override the ClassName in the output.
* `-JojobaBatch` can be used to share a runspace pool between multiple function calls, otherwise a new one is used each time.
* `-JojobaJenkins .\Jojoba.xml` will write the JUnit XML results to the specified file. If you are running under Jenkins, this isn't necessary, and this file will be written to that location automatically.

#### Need more?

[Watch the hour long video][3] (this uses an older version of the module but the main difference is less is required in the template now).

[1]: Images/Jojoba.png
[2]: Images/Test-ComputerPing.gif
[3]: https://www.youtube.com/watch?v=Ov-1n7H-tdQ
