#!/bin/bash

##########################################
#
# What: Enables shared directories in Cloud Storage
# Contact:     FSG SRE Team
#
##########################################

ENV=${1:-qatsp}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

az keyvault secret show --name haenvironments --vault-name fsgkeyvault | jq -r ".value" > shared/privateKey
chmod 600 shared/privateKey
clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")
passphrase=$(az keyvault secret show --name haenvironmentsPwd --vault-name fsgkeyvault | jq -r ".value")

#Copy the private key provided in the cluster creation to one of the master nodes

expect << EOF
    global spawn_id
    spawn scp -r -i shared/privateKey shared $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com:/home/$clusterUser
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

# #connect to the master and run the scripts to mount volumes to the docker registry key
expect << EOF
    spawn ssh -i shared/privateKey -o StrictHostKeyChecking=no  $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com 'bash -s' < buildcluster_4b.sh
    expect "Enter passphrase for key"
    send "$passphrase\r"
    expect eof
EOF

rm template.json
rm shared/privateKey
