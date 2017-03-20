# Define Script Arguments
param (
   [Parameter(Mandatory=$true)][string]$server,
   [switch] $Dns,
   [switch] $DetectProcess,
   [switch] $IncludeBestPractices,
   [switch] $Flows,
   [string] $Interface
)

if (Test-Path C:\CyberSift) {
  return 0
}

# Create the directory we'll live in
New-Item C:\CyberSift -type directory
New-Item C:\CyberSift\Downloads -type directory

# Download archives
wget https://github.com/CyberSift/vendor_binaries/blob/master/windows/packetbeat-5.2.2-windows-x86_64.zip -OutFile C:\CyberSift\Downloads\packetbeat.zip
wget https://github.com/CyberSift/vendor_binaries/blob/master/windows/winlogbeat-5.2.2-windows-x86_64.zip -OutFile C:\CyberSift\Downloads\winlogbeat.zip
wget https://github.com/CyberSift/vendor_binaries/blob/master/windows/Sysmon.zip -OutFile C:\CyberSift\Downloads\Sysmon.zip

# Function To Unzip Files
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "C:\CyberSift\Downloads\packetbeat.zip" "C:\CyberSift\packetbeat"
Unzip "C:\CyberSift\Downloads\winlogbeat.zip" "C:\CyberSift\winlogbeat"
Unzip "C:\CyberSift\Downloads\Sysmon.zip" "C:\CyberSift\sysmon"

$sysmon_config=""
$packetbeat_config=""
$winlogbeat_config=""

if ($DetectProcess -and $IncludeBestPractices) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/blob/master/sysmon/sysmon_config.xml"
} elseif ($DetectProcess) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/blob/master/sysmon/sysmon_config_net_only.xml"
} elseif ($IncludeBestPractices) {
  $sysmon_config="https://github.com/CyberSift/vendor_configs/blob/master/sysmon/sysmon_config_limited_net.xml"
}

if ($sysmon_config -ne ""){
  wget $sysmon_config -OutFile C:\CyberSift\sysmon\config.xml
  C:\CyberSift\sysmon\Sysmon64.exe -i -n -h md5 -accepteula

  $winlogbeat_config="https://github.com/CyberSift/vendor_configs/blob/master/winlogbeat/only_sysmon.yml"
  wget $winlogbeat_config -OutFile C:\CyberSift\winlogbeat\winlogbeat.yml
  Add-Content C:\CyberSift\winlogbeat\winlogbeat.yml "`noutput.elasticsearch:`n  hosts: [`"http://$server`:80/elasticsearch/`"]"
  C:\CyberSift\winlogbeat\install-service-winlogbeat.ps1
}

if ($Flows -and $Dns){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/blob/master/packetbeat/windows_flows_dns.yml"
} elseif ($Flows){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/blob/master/packetbeat/windows_flows_only.yml"
} elseif ($Dns){
  $packetbeat_config="https://github.com/CyberSift/vendor_configs/blob/master/packetbeat/windows_dns_only.yml"
}

if ($packetbeat_config -ne ""){
  wget $packetbeat_config -OutFile C:\CyberSift\packetbeat\packetbeat.yml
  Add-Content C:\CyberSift\packetbeat\packetbeat.yml "`noutput.elasticsearch:`n  hosts: [`"http://$server`:80/elasticsearch/`"]`n`npacketbeat.interfaces.device: $Interface`n"
  C:\CyberSift\packetbeat\install-service-packetbeat.ps1
}

return 0