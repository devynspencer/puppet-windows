<#
.SYNOPSIS
    Install the Puppet agent on a Windows host.

.DESCRIPTION
    Install the Puppet agent on a Windows host using msiexec. Can supply values for basic agent settings.

.PARAMETER Version
    Version of Puppet agent to install. Defaults to 'latest'.

.PARAMETER Architecture
    Processor architecture of agent to install. Defaults to 'x64'.

.PARAMETER Destination
    Location to use for Puppet agent install. Defaults to 'C:\Program Files\Puppet Labs\Puppet'

.PARAMETER DownloadPath
    Directory to download Puppet agent installer to. Defaults to '~\AppData\Local\Temp.

.PARAMETER LogPath
    Directory to write installation logs to.

.PARAMETER PuppetServer
    Hostname or fqdn of the primary Puppet server can be reached. Defaults to 'puppet'.

.PARAMETER CertificateAuthority
    Hostname or fqdn of the CA server. Defaults to 'puppet'.

.PARAMETER NodeName
    Node's certificate name, and the name it uses when requesting catalogs. Defaults to the value of `fqdn` from facter.

    For best compatibility, limit the value of certname to lowercase letters, numbers, periods, underscores, and dashes.

.PARAMETER Environment
    Node environment. Defaults to 'production'.

    Note: If a value for the environment variable already exists in puppet.conf, specifying it during installation does not override that value.

.PARAMETER AgentAccount
    Windows user account the agent service uses. Defaults to 'LocalSystem'.

    This property is useful if the agent needs to access files on UNC shares, because the default LocalService account can't access these network resources.

    The user account must already exist, and can be either a local or domain user. The installer allows domain users even if they have not accessed the machine before. The installer grants Logon as Service to the user, and if the user isn't already a local administrator, the installer adds it to the Administrators group.

.PARAMETER AgentDomain
    Domain of the agent's user account.

.PARAMETER AgentPassword
    Password for the agent's user account.

.EXAMPLE
    PS C:\> .\Install-PuppetAgent.ps1 -AgentPassword password1234
    Install the latest Puppet agent on the local system.

.EXAMPLE
    PS C:\> .\Install-PuppetAgent.ps1 -AgentPassword password1234 -Environment development
    Install a version 7.8.0 Puppet agent, and set the default environment for the node to 'development'.
#>

param (
    [string]
    $Version = 'latest',

    [ValidateSet('x64', 'x86')]
    [string]
    $Architecture = 'x64',

    [string]
    $Destination = "$env:ProgramFiles\Puppet Labs\Puppet",

    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    $DownloadPath = "$env:TEMP",

    [ValidateScript({ Test-Path -Path $_ })]
    [string]
    $LogPath,

    [string]
    $PuppetServer = 'puppet',

    [string]
    $CertificateAuthority = 'puppet',

    [string]
    $NodeName = $env:COMPUTERNAME,

    [string]
    $Environment = 'production',

    [string]
    $AgentAccount = 'LocalSystem',

    [string]
    $AgentDomain = "$env:USERDOMAIN",

    [Parameter(Mandatory)]
    [string]
    $AgentPassword
)

# Skipping pipeline structure until remote install parameter set is added

if ($Version -eq 'latest') {
    $AgentFileUri = "http://downloads.puppetlabs.com/windows/puppet/puppet-agent-$Architecture-latest.msi"
}

else {
    $AgentFileUri = "http://downloads.puppetlabs.com/windows/puppet/puppet-agent-$Version-$Architecture.msi"
}

$MsiFilePath = Join-Path -Path "$DownloadPath\$MsiFileName" -ChildPath $AgentFileUri.Split('/')[-1]
Invoke-WebRequest -Uri $AgentFileUri -OutFile $MsiFilePath

$ExecParams = @{
    FilePath = 'msiexec.exe'
    ArgumentList = '/qn', '/norestart', '/i', "'$MsiFilePath'"
    Wait = $true
    NoNewWindow = $true
}

if ($PSBoundParameters.ContainsKey('LogPath')) {
    $LogFilePath = "$LogPath\puppet-install-$(Get-Date -Format FileDateTime).txt"
    $LogArguments = '/l*', "'$LogFilePath'"
    $ExecParams.ArgumentList += $LogArguments
}

$InstallProperties = @(
    "PUPPET_SERVER=$PuppetServer"
    "PUPPET_CA_SERVER=$CertificateAuthority"
    "PUPPET_AGENT_CERTNAME=$NodeName"
    "PUPPET_AGENT_ENVIRONMENT=$Environment"
    "PUPPET_AGENT_ACCOUNT_USER=$AgentAccount"
    "PUPPET_AGENT_ACCOUNT_DOMAIN=$AgentDomain"
)

$ExecParams.ArgumentList += $InstallProperties

$InstallProcess = Start-Process @ExecParams -PassThru
$InstallProcess | Write-Host -ForegroundColor Green
