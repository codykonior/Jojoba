#
# Module manifest for module 'Jojoba'
#
# Generated by: Cody Konior
#
# Generated on: 24/02/2018
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'Jojoba.psm1'

    # Version number of this module.
    ModuleVersion        = '4.0.11'

    # Supported PSEditions
    CompatiblePSEditions = 'Core', 'Desktop'

    # ID used to uniquely identify this module
    GUID                 = 'f8daad43-0a96-4b47-a482-5f9cac943cd4'

    # Author of this module
    Author               = 'Cody Konior'

    # Company or vendor of this module
    CompanyName          = 'Cody Konior'

    # Copyright statement for this module
    Copyright            = '(c) 2017 Cody Konior. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Provides a simple method of building parallel capability into PowerShell functions and wrapping results in a unit testing format.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = 'Disposable', 'Error', 'PoshRSJob'

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = 'Start-Jojoba', 'Publish-Jojoba',
    'Write-JojobaFail', 'Write-JojobaSkip',
    'Write-JojobaProperty', 'Out-JojobaSpeech'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    # VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # The primary categorization of this module (from the TechNet Gallery tech tree).
            Category                 = "Multithreading"

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags                     = 'PoshRSJob', 'Runspace', 'RunspacePool', 'PowerShellCore', 'RSJob',
            'Jenkins', 'Jojoba', 'Testing',
            'PSEdition_Desktop', 'PSEdition_Core',
            'powershell', 'unit_testing', 'bdd', 'tdd'

            # A URL to the license for this module.
            LicenseUri               = 'https://www.gnu.org/licenses/gpl-3.0.html'

            # A URL to the main website for this project.
            ProjectUri               = 'https://github.com/codykonior/Jojoba'

            # A URL to an icon representing this module.
            IconUri                  = 'https://github.com/codykonior/Jojoba/raw/master/Images/Jojoba.png'

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # External dependent modules of this module
            # ExternalModuleDependencies = ''

            # If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
            RequireLicenseAcceptance = "False"

            # Indicates this is a pre-release/testing version of the module.
            Prerelease               = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
