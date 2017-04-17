#!/bin/bash
CSPATH="/usr/local/cybersift"
PACKETBEATPATH="/etc/packetbeat"

pkill sysdig
pkill packetbeat

sysdig -N -p"%proc.exe : %evt.arg.fd : %evt.arg.size" fd.type=ipv4 and fd.sockfamily=ip and evt.is_io=true > /var/log/sysdig.log &

echo '''packetbeat.interfaces.device: any

packetbeat.protocols.dns:
  ports: [53]
  include_authorities: true
  include_additionals: true
''' > $PACKETBEATPATH/packetbeat-cs.yml

if [ "$1" != "" ]; then
    echo '''output.elasticsearch:
      hosts: ["http://'''$1''':80/cybersift_elasticsearch/"]''' >> $PACKETBEATPATH/packetbeat-cs.yml

    $PACKETBEATPATH/packetbeat -c $PACKETBEATPATH/packetbeat-cs.yml &
    $CSPATH/LinuxAgent -url $1
else
    $PACKETBEATPATH/packetbeat -c $PACKETBEATPATH/packetbeat-cs.yml &
    $CSPATH/LinuxAgent
fi
