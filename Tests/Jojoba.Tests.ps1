Describe "jojoba" {
    Import-Module Jojoba -Force
    Import-Module PoshRSJob -Force
    Get-ChildItem $PSScriptRoot Test-*.ps1 | ForEach-Object {
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

    Context "should flag an error if no InputObject parameter or alias exists" {
        It "with manual input" {
            { Test-NoInputObject "ABC" -JojobaQuiet } | Should -Throw "Jojoba requires"
        }
        It "with pipeline input" {
            { "ABC" | Test-NoInputObject -JojobaQuiet } | Should -Throw "Jojoba requires"
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
                $results[0].Name | Should -Be "ABC"
                $results[0].Data | Should -Be "$type ABC"
                $results[1].Name | Should -Be "CDE"
                $results[1].Data | Should -Be "$type CDE"
            }
            if ($type -in "Fail", "Skip") {
                It "shows a correct Message" {
                    $results[0].Message | Should -Be "$($type) because of ABC"
                    $results[1].Message | Should -Be "$($type) because of CDE"
                }
            }
            It "has a result of $type" {
                $results[0].Result | Should -Be "$type"
                $results[1].Result | Should -Be "$type"
            }
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
            $result.OtherProperty | Should -Be "Set"
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

    Context "benchmarks" {
        $jojoba = Measure-Command { 1..10 | Test-Slow -JojobaQuiet }
        $normal = Measure-Command { 1..10 | Test-SlowNoJojoba }

        It "slow jobs should be faster ($($jojoba.Seconds)s) than without ($($normal.Seconds)s)" {
            $jojoba.Seconds | Should -BeLessThan $normal.Seconds
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
