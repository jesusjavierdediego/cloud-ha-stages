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

clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")


#Copy the private key provided in the cluster creation to one of the master nodes
echo $clusterUser
echo $(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com

scp -r -i shared/privateKey shared $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com:/home/$clusterUser

#connect to the master and run the scripts to mount volumes to the docker registry key

echo "SSH"

ssh -i shared/privateKey -o StrictHostKeyChecking=no  $clusterUser@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com 'bash -s' < buildcluster_4b.sh

#rm template.json
#rm shared/passphrase
#rm shared/privateKey
