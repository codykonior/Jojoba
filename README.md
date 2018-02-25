![][1]

[![Build status](https://ci.appveyor.com/api/projects/status/oefdf90a75hqsk69?svg=true)](https://ci.appveyor.com/project/codykonior/jojoba)

#### Description

Jojoba wraps function internals to run their pipeline inputs in parallel and output in a test format which can be understood by users, other scripts, and PowerShell. It does this by providing a simple template to follow with a few optional keywords. It's useful for fast, simple, and reliable testing and operational validation of large server environments.

Why does it exist? Because:
* When you have a lot of tests, or a lot of objects to run those tests against, things take too long to run.
* And so when you start to add Start-RSJob, Wait-RSJob, Receive-RSJob patterns to every test, it becomes painful to maintain.
* And once you start batching those tests together it becomes painful to manage jobs, job ouptut, exceptions and errors.
* And once you've handled that it becomes difficult to integrate the different styles of output with other scripts and software.

Jojoba does away with all of this so you don't need to think about it or maintain it yourself anymore. Back-end job functionality is provided by the world-class [PoshRSJob][1] runspace management module.

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
* Any pipelined input will be queued into those slots as they become available.
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
* `Write-JojobaProperty` takes a hashtable of properties and will upsert them to the unit test object, which can be returned with -JojobaPassThru. They won't appear on screen or in any JUnit XML output however.

Pester `| Should` test statements can also be used to fail a test, as these will throw a terminating exception which will be caught by Jojoba as a failure.

#### What options are there?

Parameters are passed to your function through the RemainingArguments variable not to Jojoba directly.

Common:

* `-JojobaQuiet` will suppress the Write-Host output.
* `-JojobaPassThru` will return the unit test results as standard objects.
* `-JojobaJenkins .\Jojoba.xml` will write the JUnit XML results to the specified file. This isn't necessary if you are running under Jenkins as it will be detected and written to that location automatically.

Uncommon:

* `-JojobaUnsafe` will skip setting $ErrorActionPreference to Stop and StrictMode to Latest before your scriptblock executes. This is done because jobs don't inherit these settings by default and they guarantee results.
* `-JojobaSuite` and `-JojobaClassName` can be used to override these properties in the output, though `Write-JojobaProperty` can do the same while inside `Start-RSJob`.
* `-JojobaBatch` can be used to share a runspace pool between multiple function calls, otherwise a new one is used each time.
* `-JojobaThrottle` accepts an integer to determine how many jobs will be spun up. It defaults to match the number of CPU cores. If  it's set to 0 all job functionality is disabled so you can set breakpoints and debug your function easily.

#### What are some of the gotchas?

* A PoshRSJob is a lot like a normal job:
  * It doesn't load the $profile.
  * It begins with an $ErrorActionPreference of Continue.
  * StrictMode is disabled.

  Executing a function from the command line would usually inherit those properties but functions which are farmed out to jobs do not. So if you care about these settings (and you should because it's best practice to have these set to Stop and Latest respectively), you should:

  * For standalone functions, declare them within the Start-Jojoba block.
  * Or for modules, declare them in your .psm1 file. They sets them for the entire scope of all module functions, even those executed within jobs.
* If your functions loads modules that have a TypesToProcess section then PowerShell can throw spurious errors trying to load those modules while under heavy runspace load due to PowerShell engine internal race conditions. The only solution is to remove it from the module definition file and add `Update-TypeData -PrependPath` lines to the RootModule file instead. Common modules susceptible to this include: FailoverClusters, DnsClient, and SqlServer.
* PowerShell Core 6.0.1 crashes at the end of the AppVeyor tests with a timeout problem so those tests have been temporarily disabled. I am not able to reproduce it locally.

#### Need more?

[Watch the hour long video][3]. There have been some changes in templates since the version of Jojoba presented there:

* InputObject can now be an alias rather than a parameter name.
* $JojobaBatch and $JojobaThrottle should not be hardcoded into your function definition. A ValueFromRemainingArguments parameter is required instead.
* Jojoba output is done through Write-Host rather than returning objects. If you need the object then you can use -JojobaPassThru. If you don't want to see the Write-Host output use -JojobaQuiet.

Also:

* Write-JojobaAbort is no longer supported. Use Write-JojobaFail -CriticalFailure instead. The output is slightly different.
* $JojobaCallback is no longer supported. Use -JojobaPassthru instead to pipe the test object somewhere.

[1]: Images/Jojoba.png
[2]: Images/Test-ComputerPing.gif
[3]: https://www.youtube.com/watch?v=Ov-1n7H-tdQ
[4]: https://github.com/proxb/PoshRSJob
