<#

.SYNOPSIS
Read out basic Jojoba results to a sound card.

.DESCRIPTION
Takes a Jojoba result and reads out each class, name, and result (and optional message). It will repeat failures twice.

.PARAMETER Test
A Jojoba test case.

.PARAMETER VoiceGender
Male or Female.

.PARAMETER VoiceRate
Rate of speech. 2 is a little faster than normal.

.EXAMPLE
function Test-DatabaseServer {
    param (
        [Parameter(AcceptPipelineInput)]
        $InputObject,
        $JojobaThrottle = $env:NUMBER_OF_PROCESSORS
    )
    begin {
    }
    process {
        Start-Jojoba {
            switch ($InputObject) {
                "FRODO" {
                    break
                }
                "LARRY" {
                    Write-DbFail "Offline for maintenance"
                }
                "CURLY" {
                    Write-DbFail "Is not even resolving an IP address, oh no!"
                }
            }
        }
    }
    end {
    }
}
"FRODO","LARRY","CURLY" | Test-DatabaseServer | Out-JojobaSpeech

Fake a database failure and listen to the results.

This is only an example. Do NOT write Jojoba code like this as it skips out on many Jojobs features. Specifically it does not have multi-threading (as it has no JojobaFail) and no Jenkins output.

.NOTES


#>

function Out-JojobaSpeech {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        $Test,
        $VoiceGender = "Female",
        $VoiceRate = 2
    )

    begin {
        try {
             Add-Type -Assembly System.Speech
        } catch {
            Write-Error -Message "Speech requires NET 3.0 and above"
        }
    }

    process {
        New-DisposableObject ($speech = New-Object System.Speech.Synthesis.SpeechSynthesizer) {
            $speech.SelectVoiceByHints($VoiceGender)
            $speech.Rate = $VoiceRate
            
            # This isn't perfect, but, I want to remove - signs from the class name (as it's
            # often Test-Something, etc, and leaving it there results in speech oddities),
            # but I also want to add spaces between ACRONYMS and WordsLikeThis and numbers 
            # as it sounds better for server names
            $regEx = '[^\p{Ll}\s]', ' $&'
            $speechString = "$($Test.ClassName.Replace("-", "`") -creplace $regEx, ' $&') on $($Test.Name -creplace $regEx, ' $&'), $($Test.Result)"
            $speech.Speak($speechString)
            if ($Test.Result -eq "Fail") {
                if (!$Test.Message) {
                    $speech.Speak("Repeat, $speechString with no reason")
                } else {
                    $speech.Speak("Repeat, $speechString with reason $($Test.Message)")
                }
            }
        }
    }

    end {
    }
}

