#!/bin/bash

################################
# AZURE ACS DCOS CLUSTER SCRIPT 
################################
#
# What: Delete cluster in ACS DCOS
# Contact:  FSG SRE Team
#
#################################

ENV=${1:-qatsp}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

rgExists=$(az group list | grep -i $(prop 'resourceGroup'));
nameExists=$(az network public-ip list | grep -i dcos-master-ip-$(prop 'groupName')-mgmt);


if [ "$rgExists" != "" ]
then
echo "RG $(prop 'resourceGroup') exists. Deleting $(prop 'resourceGroup') RG.";
  az group delete --location $(prop 'region') --name $(prop 'resourceGroup')
else
  echo "ResourceGroup $(prop 'resourceGroup') does not exists.";
fi


if  [ "$nameExists" != "" ]
then
   echo "Cluster name $(prop 'groupName') exists. Deleting $(prop 'groupName') cluster.";
   az group deployment delete --resource-group $(prop 'resourceGroup') --name $(prop 'groupName')
else
  echo "name $(prop 'groupName') does not exists.";
fi