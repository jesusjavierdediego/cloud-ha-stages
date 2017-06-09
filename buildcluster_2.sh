#!/bin/bash

##########################################
#
# Name:        buildcluster_2.sh
# Description: Open a SSH tunnel on ACS DCOS
# Contact:     
#
##########################################


ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

# echo $(prop 'privateKeyPath')

sudo ssh -i "$(prop 'privateKeyPath')" -v -o ExitOnForwardFailure=yes -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $(prop 'sshuser')@$(prop 'groupName')-mgmt.$(prop 'region').cloudapp.azure.com && exit

# az acs dcos browse --name containerservice-FSG_BureauSP_HAStage_QAT --resource-group $(prop 'resourceGroup') --disable-browser --ssh-key-file   $(prop 'privateKeyPath')
# az acs dcos browse -g FSG_BureauSP_HAStage_QAT -n containerservice-FSG_BureauSP_HAStage_QAT --disable-browser --ssh-key-file /home/jdediego/.ssh/id_rsa_stages
# ssh -i ~/.ssh/id_rsa_stages bureau_user@fsgbureauspqat-mgmt.northeurope.cloudapp.azure.com
# docker login fsgregistry.azurecr.io -u fsgregistry -p =uv=t=+++i+=B/0=KV=VS7/r==j5D=u6
