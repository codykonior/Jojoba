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
* A string type ValueFromPipeline or ValueFromPipelineByPropertyName argument with a name or alias of InputObject.
* A ValueFromRemainingArguments argument of any name. Any switches for Jojoba will use the -Jojoba prefix.
* `Start-Jojoba {}` wrapping code in the process block.
* `Publish-Jojoba` in the end block.

Any parameters not sent through the pipeline will be serialized to strings and so should be limited to simple types: ints, strings, bools, and switches.

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
* Failure and skip messages are not terminating by and of themselves.

![][2]

#### What else can I do?

* `Write-JojobaSkip` will mark the output as skipped, for example if some pre-condition is not met.
* `Write-JojobaFail -CriticalFailure` will flag the entire run as critically failed. This results in an $env:LASTEXITCODE of 1 and a Write-Error after all test results has been passed on. This is useful to indicate that a test didn't just fail, but requires investigation into the script logic.
* `Write-JojobaProperty` upserts a hashtable property bag to the unit test. Unit test objects can be returned with -JojobaPassThru. These properties will not display on the screen or appear in the JUnit XML output however.

#### What options are there?

Parameters are passed to your function through the RemainingArguments variable not to Jojoba directly.

Common:

* `-JojobaQuiet` will suppress the Write-Host output.
* `-JojobaPassThru` will return the unit test results as standard objects.
* `-JojobaJenkins .\Jojoba.xml` will write the JUnit XML results to the specified file. This isn't necessary if you are running under Jenkins as it will be detected and written to that location automatically.

Uncommon:

* `-JojobaSuite` and `-JojobaClassName` can be used to override these properties in the output, though `Write-JojobaProperty` can do the same while inside `Start-RSJob`.
* `-JojobaBatch` can be used to share a runspace pool between multiple function calls, otherwise a new one is used each time.
* `-JojobaThrottle` accepts an integer to determine how many jobs will be spun up. It defaults to match the number of CPU cores.

#### Need more?

[Watch the hour long video][3] (this uses an older version of the module but the main difference is less is required in the template now).

[1]: Images/Jojoba.png
[2]: Images/Test-ComputerPing.gif
[3]: https://www.youtube.com/watch?v=Ov-1n7H-tdQ
