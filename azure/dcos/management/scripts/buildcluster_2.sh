#!/bin/bash

##########################################
#
# What: Open a SSH tunnel on ACS DCOS
# Contact:     FSG SRE Team
#
##########################################


ENV=${1:-qatsp}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

# Kill pre-existing tunnels
ps axuf | grep 2222 | grep ssh | awk '{print "kill -9 " $1}'

# Write private key file 
az keyvault secret show --name haenvironments --vault-name fsgkeyvault | jq -r ".value" > shared/privateKey

chmod 600 shared/privateKey

clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")
passphrase=$(az keyvault secret show --name haenvironmentsPwd --vault-name fsgkeyvault | jq -r ".value")

expect << EOF
    spawn ssh -i shared/privateKey -v -o StrictHostKeyChecking=no -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

exit 0


