<#

.SYNOPSIS
Speak Jojoba test results to a sound card.

.DESCRIPTION
Speech includes the class name, name, and result. If the result is a failure
the message will be repeated. If there is a message on a failure it will be
spoken during the repeat.

.PARAMETER Test
Output from a Jojoba function called with -JojobaPassThru.

.PARAMETER VoiceGender
Male or Female.

.PARAMETER VoiceRate
Rate of speech. 2 is a little faster than normal.

.EXAMPLE
function Test-DatabaseServer {
    param (
        [Parameter(ValueFromPipeline)]
        $ServerInstance,
        [Parameter(ValueFromRemainingArguments)]
        $Jojoba
    )
    begin {
    }
    process {
        Start-Jojoba {
            switch ($ServerInstance) {
                "FRODO" {
                    # Simulate it finishing last
                    Start-Sleep -Seconds 5
                    break
                }
                "LARRY" {
                    Write-JojobaFail "Offline for maintenance"
                }
                "CURLY" {
                    Write-JojobaFail "Is not even resolving an IP address!"
                }
            }
        }
    }
    end {
        Publish-Jojoba
    }
}
"FRODO","LARRY","CURLY" | Test-DatabaseServer -JojobaPassThru | Out-JojobaSpeech

Fake the failure of a database test and listen to the results.

#>

function Out-JojobaSpeech {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
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
        foreach ($service in (Get-Service AudioEndpointBuilder, audiosrv)) {
            if ($service.Status -ne "Running") {
                Write-Warning "$($service.Name) is required for speech but is not Running"
            }

            return
        }

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
                    $speech.Speak("I repeat, $speechString with no message")
                } else {
                    $speech.Speak("I repeat, $speechString with message $($Test.Message)")
                }
            }
        }
    }

    end {
    }
}
