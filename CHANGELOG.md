# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

### Changed
- Old `$Jojoba` parameters should now be removed from the function header as
they are picked up in another way. Functions now require a ValueFromPipeline
parameter with a name or alias of InputObject, and ValueFromRemainingArguments
parameter of any name.
- Jojoba no longer outputs objects to the pipeline by default. It can be
made to occur with `-JojobaPassThru`. Host output can be silenced with
`-JojobaQuiet`.
- `Write-JojobaAbort` replaced with `Write-JojobaFail -CriticalFailure`. Also
these critical failures now return normal test results, with $LASTEXITCODE = 1
and an extra terminating Write-Error at the end of the pipeline. Previously
only a Write-Error was returned and no results.

### Fixed
- Test output now populates as tests complete rather than after all tests have
completed.
