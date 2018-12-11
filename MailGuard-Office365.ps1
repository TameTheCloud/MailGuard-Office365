Clear-Host

#----------------[ Inputs ]------------------------------------------------------
#region User Inputs (domain name, etc)
#Gets the email Domain to do validation 
write-host "What is the domain name you are implementing this for?" -ForegroundColor Yellow   
$EmailDomain = Read-Host "e.g mycustomersdomain.com.au"

#Gets the Smart Filter
Write-host 'What is the Smart Host provided by MailGuard?' -ForegroundColor yellow
$SmartHost = Read-Host "e.g filter.mycust.mailguard.com.au"

#Connect to Office 365 / Exchange Online
write-host 'Enter O365 Credentials' -ForegroundColor Yellow
Start-Sleep 2
if (!($UserCredential)) {
$UserCredential = (Get-Credential)
}
#----------------[ Declarations ]------------------------------------------------------
#Inbound / Recieve Connector. Add to this list if it changes.
$MGReceiveConnectorIPs = '70.84.109.196/32',
'108.168.255.217/32',
'108.168.255.216/32',
'50.23.252.166/32',
'50.23.246.238/32',
'174.36.235.195/32',
'69.16.202.216/32',
'69.16.202.203/32',
'203.21.125.33/32',
'203.21.125.32/32',
'67.15.24.9/32',
'67.15.52.7/32'

$ConnectedtoExchange = $null
$ConnectorsCreated = $null
$SPFRecordFailed = $null
$MXRecordFailed = $null
$ConnectorsEnable = $null

#----------------[ Functions ]---------------------------------------------------------
Function Connect-ExchangeOnline{
    Param()
    
    Begin{
      Write-Host "Start Connect-ExchangeOnline function..." -ForegroundColor Yellow
    }
    
    Process{
      Try{
        if (!($Session)){
        
        $commands = 'New-InboundConnector','New-OutboundConnector','Set-InboundConnector','Set-OutboundConnector','Get-InboundConnector','Get-OutboundConnector'

        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection -ErrorAction stop
        Import-PSSession $Session  -DisableNameChecking:$true -AllowClobber:$true -CommandName $Commands -ErrorAction Stop
            }
      }
      
      Catch{
        Write-Error "Error, cannot connect to Exchange Online because $_" -ErrorAction Stop
        Break
      }
  
    }
    
    End{
      If($?){ # only execute if the function was successful.
        
        Write-Host "Completed Connect-ExchangeOnline function."  -ForegroundColor Green
        $ConnectedtoExchange = $true
      }
    }
 }
Function Create-MailGuardConnectors{
    Param()
    
    Begin{
      Write-Host "Start Create-MailGuardConnectors function..." -ForegroundColor Yellow
    }
    
    Process{
      Try{
        #Creates Recieve Connector
        Write-Host 'Creating Receive Connector...' -ForegroundColor yellow
        New-InboundConnector -name "MailGuard Receive Connector" -SenderDomains * -SenderIPAddresses $MGReceiveConnectorIPs -RestrictDomainsToIPAddresses $true -RequireTls $true -Enabled $false -ErrorAction Stop | Out-Null 
        #Creates Send Connector
        Write-Host 'Creating Send Connector...' -ForegroundColor yellow
        New-OutboundConnector -name "MailGuard Send Connector" -RecipientDomains * -SmartHosts $SmartHost -TlsSettings CertificateValidation -UseMXRecord $false -Enabled $false -ErrorAction Stop | Out-Null
        }
      
      Catch{
        Write-Error "Error description: $_" -ErrorAction Stop
        Break
      }
  
    }
    
    End{
      If($?){ # only execute if the function was successful.
        
        Write-Host "Completed Create-MailGuardConnectors function."  -ForegroundColor Green
        $ConnectorsCreated = $true
      }
    }
}
Function Enable-MailGuardConnectors{
    Param()
    
    Begin{
      Write-Host "Start Enable-MailGuardConnectors function..." -ForegroundColor Yellow
    }
    
    Process{
      Try{
        #Enables Recieve Connector
        Write-Host Enabling Send/Receive Connectors -ForegroundColor yellow
        Get-InboundConnector -Identity "MailGuard Receive Connector" | Set-InboundConnector -Enabled $true
        Get-OutboundConnector -Identity "MailGuard Send Connector" | Set-OutboundConnector -Enabled $true

        }
      
      Catch{
        Write-Error "Error description: $_" -ErrorAction Stop
        Break
      }
  
    }
    
    End{
      If($?){ # only execute if the function was successful.
        
        Write-Host "Completed Enable-MailGuardConnectors function."  -ForegroundColor Green
        $ConnectorsEnable = $true
      }
    }
}
Function Check-SPFRecord{
    Param()
    
    Begin{
      Write-Host "Start Check-SPFRecord function..." -ForegroundColor Yellow
    }
    
    Process{
      Try{
     #Checks SPF has Mailguard
    $SPFRecord = Resolve-DnsName -Name $EmailDomain -Type TXT  -server 8.8.8.8 | Where-Object {$_.Strings -like '*v=spf1*'} | Select-Object -ExpandProperty strings
        if ($SPFRecord -notlike "*include:customer.mailguard.com.au*"){ 
        throw "Your SPF Record does not include Mailguard's include:customer.mailguard.com.au. Please manually check and then enable the connectors manually within ECP"
        }
    
    }
              
      Catch{
        Write-Error "Error description: $_" -ErrorAction Stop
        $SPFRecordFailed = $true
        Break
      }
    }  

    
    End{
      If($?){ # only execute if the function was successful.
        Write-Host "Completed Check-SPFRecord function." -ForegroundColor Green
        }
    }
}
Function Check-MXRecord{
    Param()
    
    Begin{
      Write-Host "Start Check-MXRecord function..." -ForegroundColor Yellow
    }
    
    Process{
      Try{
     #Checks SPF has Mailguard
     $MXRecord = Resolve-DnsName -Name $EmailDomain -Type MX -server 8.8.8.8
     if ($MXRecord.NameExchange -notlike "*.mailguard.com.au*"){
      throw "Your MX Record does not include Mailguard's records. Please manually check and then enable the connectors manually within ECP"
        }
    
    }
              
      Catch{
        Write-Error "Error description: $_" -ErrorAction Stop
        $MXRecordFailed = $true
        Break
      }
    }  

    
    End{
      If($?){ # only execute if the function was successful.
        Write-Host "Completed Check-MXRecord function." -ForegroundColor Green
        }
    }
}

#----------------[ Main Execution ]----------------------------------------------------

Connect-ExchangeOnline
Create-MailGuardConnectors
Check-MXRecord
Check-SPFRecord

#Prompt Users to to Enable Connectors
Write-host "Would you like to Enable the MailGuard Connectors? (Default is yes)" -ForegroundColor Yellow 
    $Readhost = Read-Host " ( y / n ) " 
    Switch ($ReadHost) 
        { 
        Y {Write-host "Yes, Check Enable them"; Enable-MailGuardConnectors} 
        N {Write-Host "No, Don't";} 
        Default {Write-Host "Default, Enable DNS "; Enable-MailGuardConnectors} 
        }
    


