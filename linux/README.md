# CyberSift Linux Agent

The CyberSift Linux endpoint agent is provided to enable the collection of DNS and IP records directly from the endpoint being monitored. This has a couple of advantages:

  - It enables you to collect logs in a decentralized manner, i.e. when there are no firewalls to collect syslog or central DNS servers to monitor - both cases we commonly find in cloud deployments.
  - Since the agent is installed directly on the endpoint, it is possible to map flows with the process that generated them. This allows CyberSif to log the program that generated the connections, which is extremely helpful in threat hunting and forensic analysis

## Prerequisites

LinuxAgent depends on the following two open source programs:

  - [Packetbeat](https://www.elastic.co/guide/en/beats/packetbeat/5.2/packetbeat-installation.html)   
  - [Sysdig](http://www.sysdig.org/install/)
  
  Click on the links above for instructions on how to install each program
  
  ## Installing LinuxAgent
  
   - Download the [LinuxAgent binary from here](https://github.com/CyberSift/CyberSift_Endpoint_Agents/raw/master/linux/LinuxAgent). Place the binary into a known location (we recommend "/usr/local/cybersift") and make a note of that location for later use
   
   ``` wget https://github.com/CyberSift/CyberSift_Endpoint_Agents/raw/master/linux/LinuxAgent -O /usr/local/cybersift/LinuxAgent
   ```
   
   - Download the [LinuxAgent script from here](https://raw.githubusercontent.com/CyberSift/CyberSift_Endpoint_Agents/master/linux/LinuxAgent.sh). 
   
   ```
   wget https://raw.githubusercontent.com/CyberSift/CyberSift_Endpoint_Agents/master/linux/LinuxAgent.sh -O /usr/local/cybersift/LinuxAgent.sh
   ```
   
   This startup script automatically configures and starts Packetbeat and Sysdig, and subsequently starts the actual LinuxAgent binary
   
   - Make sure both files have the executable permission:
   
   ```
   chmod +x /usr/local/cybersift/LinuxAgent.sh
   chmod +x /usr/local/cybersift/LinuxAgent
   ```
     
# Using LinuxAgent

- First, confirm that the first two parameters set in the LinuxAgent.sh script match your enironment:

```
CSPATH="/usr/local/cybersift"
PACKETBEATPATH="/etc/packetbeat"
```
The CSPATH parameter is where you downloaded the LinuxAgent binary, while PACKETBEATPATH is where you installed packetbeat. This only needs to be done once. 

- Determine your CyberSift server IP and start up the linux agent binary by using:

```
/usr/local/cybersift/LinuxAgent.sh -es_ip YOUR.IP.ADDRESS.HERE
```

This will cause the agent to start running in the foreground. In order to automatically have the agent run on startup in the background we suggest you use ["supervisor"](http://supervisord.org/). Below is a sample configuration file you can use with supervisor:

```
[program:cybersift_agent]
directory = /usr/local/cybersift
command = /usr/local/cybersift/LunixAgent -es_ip YOUR.IP.ADDRESS.HERE
umask = 022
priority = 999
autostart = true
autorestart = true
startsecs = 10
startretries = 3
exitcodes = 0,2
stopsignal = TERM
stopwaitsecs = 10
user = root
redirect_stderr = false
stdout_logfile = /var/log/cs_LunixAgent.log
stdout_logfile_maxbytes = 10MB
stdout_logfile_backups = 10
stdout_capture_maxbytes = 10MB
stderr_logfile = /var/log/cs_LunixAgent_err.log
stderr_logfile_maxbytes = 10MB
stderr_logfile_backups = 10
stderr_capture_maxbytes = 10MB
```
