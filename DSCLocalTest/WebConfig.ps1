
Configuration producta_web{
    
    LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
        }

    Node TestWebDSC
	{
    	Import-DscResource -ModuleName xPSDesiredStateConfiguration -moduleVersion 3.12.0.0
	    
        $directories = @('D:\TestFolder1','D:\TestFolder2\')
		$Number = 0
		foreach ($directory in $directories){
			File ("SetDirectory{0}" -f $Number)
			{
				Ensure = "Present"
				Type = "Directory"
				DestinationPath = $directory
			}
			$Number += 1
		}
        
        
        Script SetServerTextFiles
        {
            SetScript = {
                        Set-Content "D:\TestFolder1\Server.txt" $env:COMPUTERNAME
                        }
            TestScript = {if(((Test-Path "D:\TestFolder1\Server.txt") ))
                            {return $true}
                            else
                            {return $false}
                        }
            GetScript = {
					return @{ 
					SetScript = $SetScript 
					TestScript = $TestScript 
					GetScript = $GetScript 
                }
            }    

	    }
}
}
##########################
#### A. Parameters ####
##########################

$passFile="C:\textpass.txt"
$subscriptionName= "xEnvironments"

##########################
#### B. Azure Login Credentials ####
##########################

#1.a. If you don't have credentials stored you can run these, or fill the pop up screen with add-azurermaccount invoked.,.
#If you have not exported your credentials locally:
#$username ="aaa"
#$secpassword= Converto-SecureString "xmy" -AsPlainText -Force 
#$credential= New-Object System.Management.Automation.PSCredential ($username, $secpassword)
#$credential | Export-Clixml $passFile

#1. b: Login to Azure 
#If you have your crendentials
$acc= Import-Clixml $passFile
Add-AzureRmAccount -Credential $acc
Set-AzureRmContext -SubscriptionName $subscriptionName

##########################
#### C. Run DSC ####
##########################

#1. invoke config: 
producta_web -OutputPath (Join-Path $PSScriptRoot "TestWebDSC")  
#2. start dsc :
Set-DscLocalConfigurationManager (Join-Path $PSScriptRoot "TestWebDSC") -ComputerName localhost
Update-DscConfiguration -ComputerName localhost
Start-DscConfiguration -wait -verbose -Path (Join-Path $PSScriptRoot "TestWebDSC") -Force -ComputerName TestWebDSC
