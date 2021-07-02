. "$PSScriptRoot\Update-CertificateTrustPolicy.ps1"

<#
.SYNOPSIS
    Replaces a missing or invalid ca.pem certificate with the latest available root certificate
    from the specified Puppet server.

.DESCRIPTION
    Replaces a missing or invalid ca.pem certificate with the latest available root certificate
    from the specified Puppet server.

.PARAMETER PuppetServer
    Hostname or fqdn of the primary Puppet server can be reached. Defaults to 'puppet'.

.PARAMETER Purge
    Default behavior is to rename existing certificates instead of deleting them to assist with
    troubleshooting.

.PARAMETER PuppetCertificatePath
    Directory containing SSL certificates used to secure communications between Puppet agent
    and client. Defaults to C:\ProgramData/PuppetLabs/puppet/etc/ssl/certs"

.EXAMPLE
    PS C:\> Repair-PuppetCertificateChain -PuppetServer puppet.example.com
    Fix missing or invalid root certificate from puppet.example.com
#>

function Repair-PuppetCertificateChain {
    param (
        [string]
        $PuppetServer = 'puppet',

        [int]
        $PuppetPort = 8140,

        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        $PuppetCertificatePath = "$env:ProgramData\PuppetLabs\puppet\etc\ssl\certs",

        [switch]
        $Purge
    )

    $PuppetRootCertUri = "https://$PuppetServer`:$PuppetPort/puppet-ca/v1/certificate/ca"
    $ExistingCerts = Get-ChildItem -Path "$PuppetCertificatePath\*.pem"

    foreach ($Certificate in $ExistingCerts) {
        if ($Purge) {
            Remove-Item -Path $Certificate.FullName -Force
        }

        else {
            $CertFileName = "$(Get-Date -Format FileDateTime)_$($_.Name).old"
            Rename-Item -Path $Certificate.FullName -NewName $CertFileName
        }
    }

    Invoke-WebRequest -Uri $PuppetRootCertUri -OutFile "$PuppetCertificatePath\ca.pem"
}

Repair-PuppetCertificateChain