![][1]

[![Build status](https://ci.appveyor.com/api/projects/status/oefdf90a75hqsk69?svg=true)](https://ci.appveyor.com/project/codykonior/jojoba)

#### Description

Jojoba wraps function internals to run their pipeline inputs in parallel and output in a test format which can be understood by users, other scripts, and PowerShell. It does this by providing a simple template to follow with a few optional keywords. It's useful for fast, simple, and reliable testing and operational validation of large server environments.

Why does it exist? Because:
* The more tests you have, and the more objects you have to test, the longer everything takes to run.
* When you start running them in parallel with Start/Wait/Receive/Remove RSJob patterns it becomes painful to maintain.
* And once you start batching those tests together it becomes painful to separate jobs, job output, exceptions and errors.
* And once you've solved that it becomes difficult to integrate the different styles of output with other scripts and software.

Jojoba does away with all of this so you don't need to think about it or maintain it yourself anymore. Back-end job functionality is provided by the world-class [PoshRSJob][4] runspace management module.

___Please note: There are [breaking changes](#need-more) in Jojoba 4 from previous versions of Jojoba.___

#### Download and install Jojoba using PowerShell:

``` powershell
Install-Module -Name Jojoba
```

It is written for Windows PowerShell 5.1 and has also been tested on PowerShell Core 6.0.1 for Windows. PowerShell 5.1 introduces a lot of performance fixes for the pipeline and is required to use modern tags in the PowerShell Gallery.

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

        #region Your other arguments
        #endregion

        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )

    begin {
    }
    process {
        Start-Jojoba {
            #region Your code
            ping $ComputerName -n 1
            if (!$?) {
                Write-JojobaFail "Connection failed"
            }
            #endregion
        }
    }
    end {
        Publish-Jojoba
    }
}
```

### What happens?

![][2]

#### What really happens?

* When the pipeline starts a new runspace is created with one slot per CPU core.
* Any pipelined input will be queued and fed into those slots as they become available.
* The results are output to the host in a unit test format with distinct colouring.
  * Suite = Module
  * Class = Function
  * Name = Pipeline
  * Data = Any visible output (Write-Host, Write-Output, Write-Verbose, etc)
* Tests will pass by default if no terminating exceptions are thrown.
* Failure and skip messages are not terminating by and of themselves.

#### What else can I do?

* `Write-JojobaSkip` will mark the output as skipped, for example if some pre-condition is not met.
* `Write-JojobaFail -CriticalFailure` will flag the entire run as critically failed. This results in $global:LASTEXITCODE of 1 and a Write-Error after all test results has been passed on. This is useful to indicate that a test didn't just fail, but requires investigation into the script logic.
* `Write-JojobaProperty` takes a hash table of properties and will upsert them to the unit test object, which can be returned with -JojobaPassThru. They won't appear on screen or in any JUnit XML output however.
* Pester `| Should` assertions work and can be used because they throw terminating exceptions which are flagged by Jojoba as a failure. However you should not wrap them in Pester `Describe` or `Context` blocks as those catch the exception first.

#### What options are there?

Jojoba doesn't take parameters directly, instead parameters are passed to your function and intercepted through parameter selected to hold RemainingArguments.

Common:

* `-JojobaQuiet` will suppress the Write-Host output.
* `-JojobaPassThru` will return the unit test results as standard objects.
* `-JojobaJenkins .\Jojoba.xml` will write the JUnit XML results to the specified file. This isn't necessary if you are running under Jenkins as it will be detected and written to that location automatically.

Uncommon:

* `-JojobaUnsafe` will skip setting $ErrorActionPreference to Stop and StrictMode to Latest before your scriptblock executes. This is done because jobs don't inherit these settings by default, and using them guarantees results.
* `-JojobaSuite` and `-JojobaClassName` can be used to override these properties in the output, though `Write-JojobaProperty` can do the same while inside `Start-RSJob`.
* `-JojobaBatch` can be used to share a runspace pool between multiple function calls, otherwise a new one is used each time.
* `-JojobaThrottle` accepts an integer to determine how many jobs will be spun up. It defaults to match the number of CPU cores. If  it's set to 0 all job functionality is disabled so you can set breakpoints and debug your function easily.

#### What are some of the gotchas?

* If your functions loads modules that have a TypesToProcess section then PowerShell can throw spurious errors trying to load those modules while under heavy runspace load due to PowerShell engine internal race conditions. The only solution is to remove it from the module definition file and add `Update-TypeData -PrependPath` lines to the RootModule file instead. Common modules susceptible to this include: FailoverClusters, DnsClient, and SqlServer.
* PowerShell Core 6.0.1 crashes at the end of the AppVeyor tests with a timeout problem so those tests have been temporarily disabled. I am not able to reproduce it locally.

#### Need more?

[Watch the hour long video][3].

In Jojoba 4 there have been some changes in the templates demonstrated in that video.

* `$InputObject` can now be a parameter alias rather than being forced as the parameter name.
* `$JojobaBatch` and `$JojobaThrottle` should not be hardcoded into your function definition. A ValueFromRemainingArguments parameter is required instead.
* Jojoba output is done through Write-Host rather than returning objects. If you need the object then you can use `-JojobaPassThru`. If you don't want to see the Write-Host output use `-JojobaQuiet`.

Also these are other changes in Jojoba 4 not presented in that video:

* `Write-JojobaAbort` is no longer supported. Use `Write-JojobaFail -CriticalFailure` instead. The output is slightly different.
* `$JojobaCallback` is no longer supported. Use `-JojobaPassthru` instead to pipe the test object somewhere.

[1]: Images/Jojoba.png
[2]: Images/Test-ComputerPing.gif
[3]: https://www.youtube.com/watch?v=Ov-1n7H-tdQ
[4]: https://github.com/proxb/PoshRSJob
