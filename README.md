![][1]

[![Build status](https://ci.appveyor.com/api/projects/status/oefdf90a75hqsk69?svg=true)](https://ci.appveyor.com/project/codykonior/jojoba)

#### Description

Jojoba provides a simple template to follow for building parallel pipeline capability into functions and standardising their output for the purposes of operational validation and testing. It outputs data that can be interpreted by Jenkins.

___Please note: This version is in Alpha and documentation is still being updated.___

#### Download and install Jojoba using PowerShell:

``` powershell
Install-Module -Name Jojoba
```

It is written for Windows PowerShell 5.1 and has also been tested on PowerShell Core 6.0.1 for Windows.

#### Example

Any function using Jojoba needs a minimum of:
* A string type pipeline input with a name or alias of InputObject. _Don't use an array_.
* A ValueFromRemainingArguments argument of any name. _Switches intended for Jojoba will use the -Jojoba prefix._
* `Start-Jojoba {}` wrapping all code in the process block.
* `Publish-Jojoba` in the end block.

Any additional function parameters not sent through the pipeline will be serialized to strings and so should be limited to simple types: ints, strings, string arrays, bools, and switches.

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
* `Write-JojobaProperty` takes a hashtable of properties and will upsert them to the unit test object, which can be returned with -JojobaPassThru. They won't appear on screen or in any JUnit XML output however.

Pester `| Should` test statements can also be used to fail a test, as these will throw a terminating exception which will be caught by Jojoba as a failure.

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
