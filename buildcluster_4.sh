#!/bin/bash

##########################################
#
# What: Enables login to Image Registry
# Contact:     
#
##########################################

ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}


#Copy the private key provided in the cluster creation to one of the master nodes
scp -r -i $(prop 'privateKeyPath') dockerRegistry $(prop 'sshuser')@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com:/home/$(prop 'sshuser')
#scp -r -i ~/.ssh/id_rsa_stages ~/Dropbox/cloud-ha-stages/dockerRegistry bureau_user@fsgbureauspqat-mgmt.northeurope.cloudapp.azure.com:/home/bureau_user

#connect to the master and run the scripts to mount volumes to the docker registry key
ssh -i $(prop 'privateKeyPath') -o StrictHostKeyChecking=no  $(prop 'sshuser')@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com 'bash -s' < buildcluster_4b.sh
