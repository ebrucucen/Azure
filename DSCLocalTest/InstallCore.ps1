Configuration InstallCoreModules
{
    param(
        [string[]]$modules,
        [string]$repository
    )

    LocalConfigurationManager
    {
        RebootNodeIfNeeded = $false
    }

    Import-DscResource -ModuleName PackageManagementProviderResource

    foreach ($module in $modules)
    {
        PSModule ("InstallModule{0}" -f $module)
        {
            Ensure             = "Present"
            Name               = $module
            InstallationPolicy = "Trusted"
            Repository = $repository
        }
    }    
}

#The first time on the machine, to test scripts locally: 
#1. Open the firewall, set the permissions for remote execution forcefully
winrm quickconfig -q -force
#2. Install module/clone/copy from github
Install-Module PackageManagementProviderResource
#3. Execute the configuration 
InstallCoreModules -modules @("xPSDesiredStateConfiguration","cChoco","xNetworking","xStorage","xPowerShellExecutionPolicy") -repository "PSGallery"
#4. Start the lcm
Set-DscLocalConfigurationManager -Path .\InstallCoreModules
#5. Run the configuration to install required modules
Start-DscConfiguration -Path .\InstallCoreModules -Wait -Force