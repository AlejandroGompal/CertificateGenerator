#requires -version 2
<#
.SYNOPSIS
  This script will help you to generate a CA Root Certificate and a PFX too, so you can
  use it to have your applications locally or even in testing servers.
.DESCRIPTION
  Sometimes having you Apps running with SSH protocols is mandatory and generating certificates
  becomes into a frequent/eventual task and it is not always easy to remember all those commands.
  Nothing better than a script that does all the dirty work for you ;).
.PARAMETER <Parameter_Name>
  FriendlyName: It is the name you will see to identify your certificate once it is installed
  CnfFilePath: This the path where your configuration is located
.INPUTS
  CONFIGURATION FILE: it is a simple .cnf file which contains all the domains you want to cover 
  with the certificate, condier the example below a template

    [ req ]
    default_bits        = 4096
    distinguished_name  = req_distinguished_name
    req_extensions      = SAN
    extensions          = SAN
    [ req_distinguished_name ]
    countryName         = myCountry
    stateOrProvinceName = myProvince
    localityName        = myCity
    organizationName    = myOrgan
    [SAN]
    subjectAltName      = DNS:my.domaine.any,IP:999.999.999
    extendedKeyUsage    = serverAuth
    basicConstraints    = CA:TRUE,pathlen:0

  Make sure you file is under UTF-8
.OUTPUTS
  The script will generate several outputs but the ones really matter are:
  - ca.pem
  - certificate.pfx
.NOTES
  Version:        1.0
  Author:         Alejandro Gomez
  Creation Date:  2023-02-16
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\PFX-Certificate-Generator FriendlyName "YourCertificate" CnfFilePath ".\my.conf"
#>

#---------------------------------------------------------[Parameters]--------------------------------------------------------

param(
  [Parameter(
    Mandatory = $True,
    HelpMessage = "Enter a friendly name for your certificate"
  )]
  [string]$FriendlyName,
  [Parameter(
    Mandatory = $True,
    HelpMessage = "Enter the path where your .cnf file is located"
  )]
  [string]$CnfFilePath,
  [Parameter(
    Mandatory = $True,
    HelpMessage = "Want it automatically installed locally?"
  )]
  [string]$InstallOnCurrentMachine = "False",
  [Parameter(
    HelpMessage = "Type the path where all the ourcomes will be droped in"
  )]
  [string]$OutPath = '.\'
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
# . "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = $OutPath
$sLogName = "PFX-Certificate_$sScriptVersion.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Write-Log {
  param (
      [Parameter(Mandatory=$False, Position=0)]
      [String]$Entry
  )

  "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') $Entry" | Out-File -FilePath $sLogFile -Append
  Write-Host $Entry -ForegroundColor DarkGreen -BackgroundColor White
}

Function Join-Out-Path {
  param (
    [Parameter(Mandatory=$True, Position=0)]
    [String]$FileName
  )

  return Join-Path -Path $OutPath -ChildPath $FileName
}

Function Generate-Certificate{
  Param()
  
  Begin{
    Write-Log -Entry "Starting Certificate generation..."
  }
  
  Process{
    Try{
      Write-Log -Entry "Generating CA..."
      Write-Log -Entry "Generating RSA"
      openssl genrsa `
        -aes256 `
        -out (Join-Out-Path "ca-key.pem") 4096
      Write-Host 
      Write-Log -Entry "Generating a public CA Cert"
      openssl req `
        -new `
        -x509 `
        -sha256 `
        -days 825 `
        -key (Join-Out-Path "ca-key.pem") `
        -out (Join-Out-Path "ca.pem")
      Write-Host 
      Write-Log -Entry "Here is the detail of your CA so far"
      openssl x509 `
        -in (Join-Out-Path "ca.pem") `
        -text

      Write-Host 
      Write-Host 

      Write-Log -Entry "Generating Certificate..."
      Write-Log -Entry "Creating a RSA key"
      openssl genrsa `
        -out (Join-Out-Path "cert-key.pem") 4096
      Write-Host 
      Write-Log -Entry "Creating a Certificate Signing Request (CSR)"
      openssl req `
        -new `
        -sha256 `
        -subj "/CN=*.local.com" `
        -key (Join-Out-Path "cert-key.pem") `
        -out (Join-Out-Path "cert.csr")
      Write-Host 
      Write-Log -Entry "Creating the certificate"
      openssl x509 `
        -req `
        -sha256 `
        -days 825 `
        -in (Join-Out-Path "cert.csr") `
        -CA (Join-Out-Path "ca.pem") `
        -CAkey (Join-Out-Path "ca-key.pem") `
        -out (Join-Out-Path "cert.pem") `
        -extfile (Join-Out-Path "extfile.cnf") `
        -CAcreateserial
      
      Write-Host 

      Write-Log -Entry "Exporting to PFX"
      openssl pkcs12 `
        -export `
        -inkey (Join-Out-Path "cert-key.pem") `
        -in (Join-Out-Path "cert.pem") `
        -name $FriendlyName -out (Join-Out-Path "certificate.pfx")

      if ([bool]::Parse($InstallOnCurrentMachine))
      {
        Write-Log -Entry "Installing Certificates Locally..."
        Import-Certificate -FilePath (Join-Out-Path "ca.pem") -CertStoreLocation Cert:\LocalMachine\Root
        $pass = Read-Host 'What is the private password?' -AsSecureString
        Import-PfxCertificate -FilePath (Join-Out-Path "certificate.pfx") -CertStoreLocation Cert:\LocalMachine\My -Password $pass -Exportable
      }
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
Generate-Certificate
Log-Finish -LogPath $sLogFile