# MailGuard-Office365
.Automate the Stacking of MailGuard mail filtering services with Office 365.
.This script is designed to simplify the stacking of MailGuard (www.mailguard.com.au) email filtering service with Exchange Online / Office 365.

# What you will need
.A valid MailGuard subscription for your domain and the base setup completed.
.A Global Admin for your Office 365 tenant with a verified domain.
.PowerShell Console running 5.0 or above


# What the Script will do
.Create Receive/Inbound connector with MailGuard's IP List (Accurate at time of this commit)
.Create Send/Outbound Connector
.Check DNS and give you the option to enable the connectors

# Instructions
1. Download the MailGuard-Office365.ps1 script
2. Start Powershell and Load the script (Don't forget to set your executionpolicy)
3. Follow the instructions given by the script.

# Instructions
. Check out detailed guide at http://tamethe.cloud/mailguardstacking/
