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
