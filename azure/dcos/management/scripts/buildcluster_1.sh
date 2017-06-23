#!/bin/bash

################################
# AZURE ACS DCOS CLUSTER SCRIPT 
################################
#
# What: Executes the steps needed on ACS DCOS
# Content:
#    - a scaleset of x amount of machines/nodes for the master (x is parameterized value)
#    - a scaleset of x amount of machines/nodes for the agents  (x is parameterized value)
#    - an internal azure loadbalancer 
#    - an external azure loadbalancer 
#    - network security groups for securing differents vlans
#    - a public ip adress for accessing the master node(s)
#    - a public ip adress for accessing the agent node(s)
# Steps:
#   - Installs a loadbalancer
#   - create network loadbalancer rule (also for loadbalancer if needed)
#   - create network security group rule (also for loadbalancer if needed)
# Contact:  FSG SRE Team
#
#################################

ENV=${1:-qatsp}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

clusterPublicKey=$(az keyvault secret show --name haenvironmentsPub --vault-name fsgkeyvault | jq -r ".value")
clusterUser=$(az keyvault secret show --name haenvironmentsUsr --vault-name fsgkeyvault | jq -r ".value")
rgExists=$(az group list | grep -i $(prop 'resourceGroup'));
nameExists=$(az network public-ip list | grep -i dcos-master-ip-$(prop 'groupName')-mgmt);



cat acs/acs-dcos-deploy.json | sed 's/XXX_USER_XXX/'$clusterUser'/g' | sed 's/XXX_AGENTVMSIZE_XXX/'$(prop 'agentVmSize')'/g' | sed 's/XXX_MASTERCOUNT_XXX/'$(prop 'mastercount')'/g' |  sed 's/XXX_AGENTCOUNT_XXX/'$(prop 'agentcount')'/g' | sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' | sed "s|XXX_PUBLICKEY_XXX|$clusterPublicKey|" > template.json;


if [ "$rgExists" == "" ]
then
  az group create --location $(prop 'region') --name $(prop 'resourceGroup')
else
  echo "ResourceGroup $(prop 'resourceGroup') already exists, using existing group...";
fi


if  [ "$nameExists" == "" ]
then
  az group deployment create --resource-group $(prop 'resourceGroup') --name $(prop 'groupName') --template-file template.json
else
  echo "name $(prop 'groupName') already exists. Deleting previous cluster and create a new one.";
   az group deployment delete --resource-group $(prop 'resourceGroup') --name $(prop 'groupName')
   az group deployment create --resource-group $(prop 'resourceGroup') --name $(prop 'groupName') --template-file template.json
fi