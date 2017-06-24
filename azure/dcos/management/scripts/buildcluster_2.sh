#!/bin/bash

##########################################
#
# What: 
# 1-Create shared volumes in all nodes
# 2-Open a SSH tunnel on ACS DCOS
# 
# Contact:     FSG SRE Team
#
##########################################


ENV=${1}
PWD=${2}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

# Kill pre-existing tunnels
ps axuf | grep 2222 | grep ssh | awk '{print "kill -9 " $1}'

# Write private key file 
az keyvault secret show --name haenvironments --vault-name fsgkeyvault | jq -r ".value" > shared/privateKey
az keyvault secret show --name haenvironmentsPwd --vault-name fsgkeyvault | jq -r ".value" > shared/passphrase

chmod 600 shared/privateKey

clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")
passphrase=$(az keyvault secret show --name haenvironmentsPwd --vault-name fsgkeyvault | jq -r ".value")

# Remove possible entries in known_hosts for the current cluster
ssh-keygen -f "~/.ssh/known_hosts" -R $(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com

# Copy the private key provided in the cluster creation to one of the master nodes
expect << EOF
    spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/known_hosts -r -i shared/privateKey shared  $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com:/home/$clusterUser
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

# Executes script to get the shared volume in all nodes in the cluster
expect << EOF
    spawn ssh -o StrictHostKeyChecking=no -i shared/privateKey  $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com shared/createShared.sh
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

# Open SSH tunnel
expect << EOF
    spawn sudo ssh-keygen -f "/root/.ssh/known_hosts" -R [$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com]:2200
    expect "password"
    send "$PWD\r"
    expect eof
EOF

expect << EOF
    spawn sudo ssh -o StrictHostKeyChecking=no -i shared/privateKey -v -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com
    expect "password"
    send "$PWD\r"
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

exit 0


