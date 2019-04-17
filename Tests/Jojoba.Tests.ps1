Describe "Jojoba" {
    Import-Module Jojoba -Force
    Import-Module PoshRSJob -Force

    Get-ChildItem .\Tests\TestScripts\Test-*.ps1 | ForEach-Object {
        Write-Verbose "Loading $($_.FullName)"
        . $_.FullName
    }

    Push-Location

    BeforeEach {
        $env:JENKINS_SERVER_COOKIE = $null
        Set-Location $TestDrive
        if (Test-Path .\Jojoba.xml) {
            Remove-Item .\Jojoba.xml
        }
    }

    Context "should not flag an error if no InputObject parameter or alias exists" {
        It "with manual input" {
            { Test-NoInputObject "ABC" -JojobaQuiet } | Should -Not -Throw "Jojoba requires"
        }
        It "with pipeline input" {
            { "ABC" | Test-NoInputObject -JojobaQuiet } | Should -Not -Throw "Jojoba requires"
        }
    }
    Context "should flag an error if no ValueFromPipeline parameter exists" {
        It "with manual input" {
            { Test-NoValueFromPipeline "ABC" -JojobaQuiet } | Should -Throw "Jojoba requires"
        }
    }
    Context "should flag an error if no ValueFromRemainingArgument parameter exists" {
        It "with manual input" {
            { Test-NoRemainingArgument "ABC" -JojobaQuiet } | Should -Throw "Jojoba requires"
        }
        It "with pipeline input" {
            { "ABC" | Test-NoRemainingArgument -JojobaQuiet } | Should -Throw "Jojoba requires"
        }
    }
    Context "works under normal conditions" {
        It "with manual input" {
            { Test-Pass "ABC" -JojobaQuiet } | Should -Not -Throw
        }
        It "with pipeline input" {
            { "ABC" | Test-Pass -JojobaQuiet } | Should -Not -Throw
        }
    }
    Context "special failures are caught" {
        It "a throw / exception" {
            $result = "ABC" | Test-FailException -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be Fail
            $result.Message | Should -Be "Fail because of ABC"
        }
        It "a Pester test statement" {
            $result = "ABC" | Test-FailPester -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be Fail
            $result.Message | Should -Match "Expected strings to be the same"
        }
    }
    Context "has working switches" {
        It "quiet is quiet" {
            $result = "ABC" | Test-Pass -JojobaQuiet *>&1
            $result | Should -BeNullOrEmpty
        }
        It "passthru passes an object through" {
            $result = "ABC" | Test-Pass -JojobaQuiet -JojobaPassThru
            $result | Should -Not -BeNullOrEmpty
        }
    }
    foreach ($type in "Pass", "Fail", "Skip") {
        Context "results should be sane during a $type result" {
            $results = "ABC", "CDE" | &Test-$type -JojobaQuiet -JojobaPassThru
            It "returns multiple results" {
                $results | Should -Not -BeNullOrEmpty
                $results.Count | Should -Be 2
            }
            It "has a correct Suite and ClassName" {
                $results | ForEach-Object { $_.ClassName | Should -Be "Test-$type" }
                $results | ForEach-Object { $_.Suite | Should -BeNullOrEmpty }
            }
            It "has correct Name and Data" {
                $results.Count | Should -Be 2
                foreach ($result in $results) {
                    $result.Name | Should -MatchExactly "(ABC|CDE)"
                    $result.Data | Should -Be "$type $($result.Name)"
                }
            }
            if ($type -in "Fail", "Skip") {
                It "shows a correct Message" {
                    $results.Count | Should -Be 2
                    foreach ($result in $results) {
                        $result.Message | Should -Be "$type because of $($result.Name)"
                    }
                }
            }
            It "has a result of $type" {
                $results.Count | Should -Be 2
                foreach ($result in $results) {
                    $result.Result | Should -Be $type
                }
            }
        }
    }
    Context "non-Jojoba non-pipeline components are passed on" {
        It "switch" {
            $result = "ABC" | Test-Switch -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Switch False"
            $result = "ABC" | Test-Switch -SomeSwitch:$false -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Switch False"
            $result = "ABC" | Test-Switch -SomeSwitch -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Switch True"
        }
        It "bool" {
            $result = "ABC" | Test-Bool -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Bool False"
            $result = "ABC" | Test-Bool -SomeBool $false -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Bool False"
            $result = "ABC" | Test-Bool -SomeBool $true -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Bool True"
        }
        It "ints" {
            $result = "ABC" | Test-Int -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Int 0"
            $result = "ABC" | Test-Int -SomeInt 1 -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Int 1"
            $result = "ABC" | Test-Int -SomeInt 2 -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Int 2"
        }
        It "string" {
            $result = "ABC" | Test-String -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "String "
            $result = "ABC" | Test-String -SomeString "ABC" -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "String ABC"
            $result = "ABC" | Test-String -SomeString 2 -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "String 2"
        }
        It "string-compatible arrays" {
            $result = "ABC" | Test-Array -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Array "
            $result = "ABC" | Test-Array -SomeArray "ABC", "BCD", "2" -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Array ABC BCD 2"
            $result = "ABC" | Test-Array -SomeArray "ABC", "BCD", 2 -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "Array ABC BCD 2"
        }
    }
    Context "obscure portions should work" {
        It "-JojobaSuite override" {
            $result = "ABC" | Test-Pass -JojobaSuite "MySuite" -JojobaQuiet -JojobaPassThru
            $result.Suite | Should -Be MySuite
        }
        It "-JojobaClassName override" {
            $result = "ABC" | Test-Pass -JojobaClassName "MyClass" -JojobaQuiet -JojobaPassThru
            $result.ClassName | Should -Be MyClass
        }
        It "Write-JojobaFail -CriticalFailure" {
            { $result = "ABC" | Test-CriticalFailure -JojobaQuiet -JojobaPassThru } | Should -Throw
        }
        It "Write-JojobaProperty" {
            $result = "ABC" | Test-Property -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be "Pass"
            $result.OtherProperty | Should -Be "Set"
        }
        It "Write-JojobaProperty update" {
            $result = "ABC" | Test-PropertyUpdate -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be "Pass"
            $result.OtherProperty | Should -Be "Update"
        }
        It "Skip should not override Fail" {
            $result = "ABC" | Test-FailSkip -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be "Fail"
        }
        It "-Verbose should work on the calling function" {
            # It should simply add a VERBOSE: Pass ABC to the Data section.
            $result = "ABC" | Test-Verbose -Verbose -JojobaQuiet -JojobaPassThru
            $result.Data | Should -Be "VERBOSE: Pass ABC"
        }
        It "-Verbose should NOT output PoshRSJob stuff" {
            $result = "ABC" | Test-Verbose -Verbose -JojobaQuiet -JojobaPassThru *>&1
            $result.GetType().FullName | Should -Not -Be "Object[]"
            $result.GetType().Name | Should -Be "PSCustomObject"
        }
    }
    Context "default and unsafe mode work as predicted" {
        It "default ErrorActionPreference catches errors" {
            $result = "ABC" | Test-ErrorActionPreference -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be Fail
        }
        It "unsafe ErrorActionPreference ignores errors" {
            $result = "ABC" | Test-ErrorActionPreference -JojobaQuiet -JojobaPassThru -JojobaUnsafe
            $result.Result | Should -Be Pass
        }
        It "default StrictMode catches errors" {
            $result = "ABC" | Test-StrictMode -JojobaQuiet -JojobaPassThru
            $result.Result | Should -Be Fail
        }
        It "unsafe StrictMode ignores errors" {
            $result = "ABC" | Test-StrictMode -JojobaQuiet -JojobaPassThru -JojobaUnsafe
            $result.Result | Should -Be Pass
        }
    }
    Context "jenkins functionality works" {
        It "won't trigger under normal conditions" {
            "ABC", "CDE" | Test-Pass -JojobaQuiet
            ".\Jojoba.xml" | Should -Not -Exist
        }
        It "works when explicitly defined" {
            "ABC", "CDE" | Test-Pass -JojobaQuiet -JojobaJenkins .\Jojoba.xml
            ".\Jojoba.xml" | Should -Exist
        }
        It "works when the environment variable is set" {
            $env:JENKINS_SERVER_COOKIE = "123"
            "ABC", "CDE" | Test-Pass -JojobaQuiet
            ".\Jojoba.xml" | Should -Exist
        }

        AfterEach {
            if (Test-Path .\Jojoba.xml) {
                Remove-Item .\Jojoba.xml
            }
            $env:JENKINS_SERVER_COOKIE = $null
        }
    }
    Context "callbacks are done one per test case" {
        # Mocks aren't appropriate here because the function doesn't already exist
        It "when passed from the command line" {
            function global:Write-Callback { param ([Parameter(ValueFromPipeline)] $Test) $Test }
            $result = "ABC", "BCD" | Test-Pass -JojobaQuiet -JojobaCallback "Write-Callback"
            $result.Count | Should -Be 2
        }
        It "should give a warning when the callback doesn't exist on the command line" {
            $result = "ABC", "BCD" | Test-Pass -JojobaQuiet -JojobaCallback "Write-NonExistentCallback" 3>&1
            $result | Should -Match "Callback.*failed"
        }
        It "when passed from within a function" {
            function global:Write-Callback { param ([Parameter(ValueFromPipeline)] $Test) $Test }
            $result = "ABC", "BCD" | Test-Callback -JojobaQuiet
            $result.Count | Should -Be 2
        }
        It "when passed from within a function and also overridden on the command line" {
            function global:Write-Callback { param ([Parameter(ValueFromPipeline)] $Test) Write-Error "Wrong one called" }
            function global:Write-CallbackOverride { param ([Parameter(ValueFromPipeline)] $Test) $Test }
            $result = "ABC", "BCD" | Test-Callback -JojobaQuiet -JojobaCallback "Write-CallbackOverride"
            $result.Count | Should -Be 2
        }
    }

    Context "benchmarks" {
        $jojoba = Measure-Command { 1..10 | Test-Slow -JojobaQuiet }
        $normal = Measure-Command { 1..10 | Test-SlowNoJojoba }

        It "Jojoba should be faster ($($jojoba.Seconds)s) than executing jobs in sequence ($($normal.Seconds)s)" {
            $jojoba.Seconds | Should -BeLessThan $normal.Seconds
        }

        $jojobaBatch = Measure-Command { 1..10 | Test-Slow -JojobaQuiet -JojobaBatch "ABC" }
        $jojobaBatchAbnormal = Measure-Command { 1..10 | ForEach-Object { $_ | Test-Slow -JojobaQuiet -JojobaBatch "ABC" } }

        It "Jojoba with a specific batch should be faster ($($jojobaBatch.Seconds)s) than if the batch feature was broken ($($jojobaBatchAbnormal.Seconds)s)" {
            $jojobaBatch.Seconds | Should -BeLessThan $jojobaBatchAbnormal.Seconds
        }

        1..2 | ForEach-Object {
            It "should be stable under extremely heavy load (500 jobs round $_)" {
                $results = 1..500 | Test-Pass -JojobaQuiet -JojobaPassThru
                $results.Count | Should -Be 500
                $results | Where-Object { $_.Result -ne "Pass" } | Should -BeNullOrEmpty
            }
        }

        1..2 | ForEach-Object {
            It "should be stable under extremely heavy load (500 jobs round $_) and manual throttling" {
                $results = 1..500 | Test-Pass -JojobaQuiet -JojobaPassThru -JojobaThrottle 100
                $results.Count | Should -Be 500
                $results | Where-Object { $_.Result -ne "Pass" } | Should -BeNullOrEmpty
            }
        }
    }

    Pop-Location
}
