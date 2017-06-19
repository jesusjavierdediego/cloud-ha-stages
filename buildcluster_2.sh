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

az keyvault secret show --name haenvironments --vault-name fsgkeyvault | jq -r ".value" > shared/privateKey
az keyvault secret show --name haenvironmentsPwd --vault-name fsgkeyvault | jq -r ".value"> shared/passphrase

clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")

# chmod +x shared/ssh-add-pass.sh

# chmod 600 shared/privateKey

# expect << EOF
#   spawn sudo ssh -i shared/privateKey -v -o ExitOnForwardFailure=yes -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com && exit
#   expect "Enter passphrase"
#   send "$(cat shared/passphrase)"
#   expect eof
# EOF


sudo ssh -i shared/privateKey -v -o ExitOnForwardFailure=yes -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com && exit