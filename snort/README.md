# Shipping SNORT logs to CyberSift

This is a very easy process (assuming Linux):

- Add a new log output to your snort config file. **NOTE: **If you already have a log of type "unified2" just make a note of the filename (in the below example "merged.log"):

`
output unified2: filename merged.log, limit 128, nostamp, mpls_event_types, vlan_event_types
`

- Install "IDSTOOLS", a python library that converts Snort unified logs to JSON:

  `pip install idstools`
  
  (CyberSift keeps a fork of this repo here: [PY-IDSTOOLS](https://github.com/CyberSift/py-idstools))
  
- Create a dirctory for us to work in:

`
mkdir /cybersift
cd /cybersift
`

- Download the program that export snort alerts to cybersift from our repo:

`
curl https://raw.githubusercontent.com/CyberSift/CyberSift_Endpoint_Agents/master/snort/SnortToEs.py -o /cybersift/SnortToEs.py
`

- Make a note of the following:
  - The snort rule classification file (by default this is */etc/snort/classification.config*)
  - The snort rule gen map file (by default this is */etc/snort/gen-msg.map*)
  - The snort rule sid map file (by default this is */etc/snort/sid-msg.map*)
  - The snort log directory (by default this is */var/log/snort*)
  - The snort log filename you chose in the first step (in our example, *merged.log*)
  - Your CyberSift server IP address (let's assume *192.168.1.1* for this example)
  
- The program can be run manually like so (assuming options listed above):
  
  `
  python /cybersift/SnortToEs.py -C /etc/snort/classification.config -G /etc/snort/gen-msg.map -S /etc/snort/sid-msg.map --directory=/var/log/snort --prefix=merged.log --bookmark=/tmp/book.tmp --cs "192.168.1.1"
  `
  
  Run this command once to ensure no errors
  
- Add the command to cron to be run every minute:

`
echo '''
* * * * * root python /cybersift/SnortToEs.py -C /etc/snort/classification.config -G /etc/snort/gen-msg.map -S /etc/snort/sid-msg.map --directory=/var/log/snort --prefix=merged.log --bookmark=/tmp/book.tmp --cs "192.168.168.170"
''' >> /etc/crontab
`

