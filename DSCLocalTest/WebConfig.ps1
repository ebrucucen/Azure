
Configuration producta_web{
    
    LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
        }

    Node TestWebDSC
	{
    	Import-DscResource -ModuleName xPSDesiredStateConfiguration -moduleVersion 3.12.0.0
        Import-DscResource -ModuleName xTimeZone

        $directories = @('C:\Utils','D:\TestFolder1')
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

         Script SetNetShDynamicPort
		{
 			GetScript = {
						return @{ 
						SetScript = $SetScript 
						TestScript = $TestScript 
						GetScript = $GetScript 
					}
			}    
			SetScript = {
				Invoke-Command  {netsh int ipv4 set dynamicportrange protocol=tcp startport=50001 numberofports=5000 } 
			
            }
     		TestScript = { 	
				$netshResult = Invoke-Command  {netsh int ipv4 show dynamicport tcp}
                $netshResult = $netshResult | Select-String : #break into chunks if colon  only
				$result = @{}
				
				$i = 0
				while($i -lt $netshResult.Length){
					$line = $netshResult[$i]
					$line = $line -split(":")
					$line[0] = $line[0].trim()
					$line[1] = $line[1].trim()
					$result.$($line[0]) = $($line[1])
					$i++
					}
				$val1=(($result.'Start Port') -eq 50001)
				$val2=($($result.'Number of Ports') -eq 5000)
				return ($val1 -and $val2)

			}
		}
        
        Script ChangeLocalisation
		{
		  GetScript = {
			return @{
			  SetScript = $SetScript
			  TestScript = $TestScript
			  GetScript = $GetScript
			}
		  }
		  TestScript = {
			((get-itemproperty "HKCU:\control panel\international" -name "scountry").sCountry -eq "United Kingdom")
		  }
		  SetScript = {
			& 'C:\Utils\ChangeLocalisation.ps1' 
		  }
		 # DependsOn = @("[xRemoteFile]Copy ChangeLocalisationScript","[xRemoteFile]Copy defaultreg","[xRemoteFile]Copy welcomereg")
		}
    
          xTimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = "GMT Standard Time"
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
