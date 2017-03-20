# Define Script Arguments
param (
   [Parameter(Mandatory=$true)][string]$server,
   [switch] $Dns,
   [switch] $DetectProcess,
   [switch] $IncludeBestPractices,
   [switch] $Flows,
   [switch] $All,
   [string] $Interface
)

if (Test-Path C:\CyberSift) {
  return 0
}

if ($All){
  $Dns = $true;
  $DetectProcess = $true;
  $IncludeBestPractices = $true;
  $Flows = $true;
}

$packetbeat_config=""

if ($Flows -and $Dns){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/raw/master/packetbeat/windows_flows_dns.yml"
} elseif ($Flows){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/raw/master/packetbeat/windows_flows_only.yml"
} elseif ($Dns){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/raw/master/packetbeat/windows_dns_only.yml"
} else {
  Write-Host "Not enough arguments provided. Either -Flows or -Dns or both must be specified. Exiting..."
  return 0
}

# Create the directory we'll live in
New-Item C:\CyberSift -type directory
New-Item C:\CyberSift\Downloads -type directory

# Download archives
wget https://github.com/CyberSift/vendor_binaries/raw/master/windows/packetbeat-5.2.2-windows-x86.zip -OutFile C:\CyberSift\Downloads\packetbeat.zip
wget https://github.com/CyberSift/vendor_binaries/raw/master/windows/winlogbeat-5.2.2-windows-x86_64.zip -OutFile C:\CyberSift\Downloads\winlogbeat.zip
wget https://github.com/CyberSift/vendor_binaries/raw/master/windows/Sysmon.zip -OutFile C:\CyberSift\Downloads\Sysmon.zip

# Function To Unzip Files
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

New-Item C:\CyberSift\sysmon -type directory
New-Item C:\CyberSift\winlogbeat -type directory
New-Item C:\CyberSift\packetbeat -type directory

Unzip "C:\CyberSift\Downloads\packetbeat.zip" "C:\CyberSift\packetbeat"
Unzip "C:\CyberSift\Downloads\winlogbeat.zip" "C:\CyberSift\winlogbeat"
Unzip "C:\CyberSift\Downloads\Sysmon.zip" "C:\CyberSift\sysmon"

$sysmon_config=""
$winlogbeat_config=""

if ($DetectProcess -and $IncludeBestPractices) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/raw/master/sysmon/sysmon_config.xml"
} elseif ($DetectProcess) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/raw/master/sysmon/sysmon_config_net_only.xml"
} elseif ($IncludeBestPractices) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/raw/master/sysmon/sysmon_config_limited_net.xml"
}

if ($sysmon_config -ne ""){
  wget $sysmon_config -OutFile C:\CyberSift\sysmon\config.xml
  C:\CyberSift\sysmon\Sysmon64.exe -i -n -h md5 -accepteula

  $winlogbeat_config="https://github.com/CyberSift/vendor_configs/raw/master/winlogbeat/only_sysmon.yml"
  wget $winlogbeat_config -OutFile C:\CyberSift\winlogbeat\winlogbeat-5.2.2-windows-x86_64\winlogbeat.yml
  Add-Content C:\CyberSift\winlogbeat\winlogbeat-5.2.2-windows-x86_64\winlogbeat.yml "`noutput.elasticsearch:`n  hosts: [`"http://$server`:80/elasticsearch/`"]"
  C:\CyberSift\winlogbeat\winlogbeat-5.2.2-windows-x86_64\install-service-winlogbeat.ps1
  Start-Service winlogbeat
}

if ($packetbeat_config -ne ""){
  wget $packetbeat_config -OutFile C:\CyberSift\packetbeat\packetbeat-5.2.2-windows-x86\packetbeat.yml
  Add-Content C:\CyberSift\packetbeat\packetbeat-5.2.2-windows-x86\packetbeat.yml "`noutput.elasticsearch:`n  hosts: [`"http://$server`:80/elasticsearch/`"]`n`npacketbeat.interfaces.device: $Interface`n"
  C:\CyberSift\packetbeat\packetbeat-5.2.2-windows-x86\install-service-packetbeat.ps1
  Start-Service packetbeat
}

return 0
