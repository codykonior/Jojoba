# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.12] - 2019-02-14
### Changes
- Default JojobaThrottle maxes out at 8 for servers with more cores. This is
  because allocating so many threads is more inefficient than limiting them.

## [4.0.11] - 2018-10-30
### Changes
- Updated internal structure and version bump for PowerShell Gallery.

## [4.0.10] - 2018-09-10
### Fixed
- Files converted to BOM-less TAB-less UTF-8.

## [4.0.9] - 2018-06-30
### Fixed
- Jenkin's JUnit parsing in xUnit became more strict which caused all tests to
  start failing. This moves around the location of some attributes in the XML
  to meet the standard and get Jenkins going again. I plan to make some more
  improvements later (adding error blocks for critical failures).

## [4.0.8] - 2018-03-19
### Fixed
- Module was not loading properly if installed from Install-Module because of
  a pattern match in the Jojoba.psm1 which was intended to prevent loading of
  *.Tests.ps1 etc but was being triggered by dots in the version number in the
  full path.

## [4.0.7] - 2018-03-12
### Changed
- If you only have a single ValueFromPipeline parameter per parameter set, this
  no longer needs a name or alias of InputObject. If you have multiple variables
  meeting this definition you can use InputObject to decide which one to use.

## [4.0.6] - 2018-03-11
### Changed
- Verbose now passes only to the `Start-Jojoba` scriptblock code. If you want
  to see verbose output from Jojoba and PoshRSJob use `-JojobaVerbose` instead.
- Updated very old entries in the CHANGELOG.

## [4.0.5] - 2018-03-07
### Changed
- Where objects are output into the Data section of a test, they are formatted
  with `Format-List` and `Out-String`. Now Out-String is limited to a width of
  up to 12 characters less than the terminal width, so when it is displayed
  on screen inside the test case (which is also formatted with `Format-List`)
  it will wrap correctly. If there's no known terminal width then nothing
  changes. This won't work for nested tests though.

## [4.0.4] - 2018-03-06
### Fixed
- `Write-JojobaProperty` would fail if called twice on the same property.
- `Write-JojobaSkip` would skip a test even if it had already failed. Now a Skip
  will always log its message but will not overwrite a previous Fail result.

## [4.0.3] - 2018-02-28
### Changed
- Order of test case properties changed for better readability.
- Test case properties Message and Data may now be $null instead of empty
strings. This helps when writing it to a database.

## [4.0.2] - 2018-02-27
### Fixed
- Removed blank lines from the top and bottom of test results for readability.

## [4.0.1] - 2018-02-26
### Added
- `Publish-Jojoba -JojobaCallback` allows use of `$PSDefaultParameterValues`
(and other methods) to automatically send all test results to a function for
storage.

## [4.0.0] - 2018-02-25
### Added
- Initial Pester tests and AppVeyor integration.
- Host colouring of tests.
- Logo.
- VS Code workspace.

### Changed
- Old `$Jojoba` parameters should now be removed from the function header as
they are picked up in another way. Functions now require a ValueFromPipeline
parameter with a name or alias of InputObject, and ValueFromRemainingArguments
parameter of any name.
- Jojoba no longer outputs objects to the pipeline by default. It can be
made to occur with `-JojobaPassThru`. Host output can be silenced with
`-JojobaQuiet`.
- `Write-JojobaAbort` replaced with `Write-JojobaFail -CriticalFailure`. Also
these critical failures now return normal test results, with `$LASTEXITCODE = 1`
and an extra terminating `Write-Error` at the end of the pipeline. Previously
only a `Write-Error` was returned and no results.

### Fixed
- Test output now populates as tests complete rather than after all tests have
completed.

## [1.4.5] 2018-02-20
### Added
- Underlying RSJobs now have the same name as the InputObject parameter. This
  makes it easier if you were to Ctrl-C to cancel a function which uses Jojoba
  and has hung, and then use `Get-RSJob` to see which jobs are stalled, and
  immediately determine what was the input that caused the hang.

## [1.4.4] 2017-11-08
### Added
- `Write-JojobaAbort` function aborts a test case with a hard exception that is
  not rolled into a test case, it just exits raw. This is to indicate a serious
  problem with test processing.
- `Write-JojobaProperty` function can add custom properties to the test case
  and takes a hashtable as input.

### Changed
- Errors in `$JojobaCallback` calls will change a test case result to Fail and
  add messages to the Data section.

### Removed
- Fast load function for the module. It was causing problems with jobs and
  under high concurrency.

## [1.0.9] 2017-04-27
### Added
- `Publish-Jojoba` now uses a progress bar, provided by `Wait-RSJob`.
- Fast load function for the module.

### Fixed
- Strings passed to caller functions can now contain ' marks.

## [1.0.8] 2017-03-02
### Changed
- Jenkins BUILD_URL detection switched for JENKINS_SERVER_COOKIE as it is
  more reliable.

## [1.0.7] 2017-02-27
### Changed
- Jenkins will now be auto-detected through the existence of the environment
  variable BUILD_URL. When this is found the Jojoba.xml will be generated.
  The existing switch still exists if you'd like to generate xml outside of
  Jenkins.
- `$JojobaBatch` parameters MUST now be defined as:
    `[string] $JojobaBatch = [System.Guid]::NewGuid().ToString()`
  This is because there is a delay on ScriptProperty being evaluated when
  it is used as a parameter, and is breaking under high concurrency load.

### Fixed
- Test case Message section is now resistant to $null objects in the pipeline.

## [1.0.6] 2017-02-23
### Changed
- Objects which are output as per normal inside your function will now be
  converted with `Select-Object -Property *` so that all bits are visible in
  the test case.

### Fixed
- Added missing dependency for the Disposable module.

## [1.0.5] 2017-02-19
### Added
- `Write-JojobaXml` now takes a -PassThru switch to pass the input object
  onwards, but it probably shouldn't be used.

### Changed
- If a `Write-JojobaCallback` function was defined this would be called with the
  test case after completion so it could be written to disk. Instead the name
  of the function to be called can be specified in a $JojobaCallback parameter
  on the function that uses Start-Jojoba. Whatever name is defined here will
  be called with one test case object at a time.
- The `$JojobaBatch` parameter on the caller should be a [string] instead of a
  [guid].

### Removed
- `Write-JojobaData` has been removed and its usage has been included inline to
  `Start-Jojoba`.

### Fixed
- `Write-JojobaXml` has better error handling for empty sections.

## [1.0.4] - 2017-02-18
### Added
- `Out-JojobaSpeech` function.
- `Start-Jojoba` can be called from a function script as well as a module.

### Changed
- The Suite of a test class will be the name of a script, if it's called from
  a script instead of from a module. If no Suite can be determined it will be
  set to "Jojoba" because the unit test format doesn't allow it to be blank.

### Fixed
- `Publish-Jojoba` sets $global:LASTEXITCODE instead of $LASTEXITCODE so that
  results propagate to the caller shell and Jenkins properly.

## [1.0.3] - 2017-02-17
### Changed
- Reduced ScriptAnalyzer warnings by removing common abbreviations.
- Function parameters of `-Parallel` changed to `-JojobaThrottle`.
- Function parameters of `-Jenkins` changed to `-JojobaJenkins`.

### Fixed
- `Write-JojobaFail` writes the correct error message now.
- `Start-RSJob` now imports the correct -Verbose flag from the caller.

## [1.0.0] - 2017-02-14
### Added
- `Start-Jojoba` function is used in the process {} block of a function to
  execute one job per pipeline input.
- `Publish-Jojoba` function is used in the end {} block of a function to
  wait for RSJobs to exit and collate their data.
- `Write-JojobaData` function to set a test case data section (internally).
- `Write-JojobaFail` function to set a test case result to Fail.
- `Write-JojobaSkip` function to set a test case result to Skip.
- `Write-JojobaXml` function used inside Publish-Jojoba to convert a test case
  to JUnit format XML for Jenkins.
