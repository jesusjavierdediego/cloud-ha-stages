#!/bin/bash

################################
# AZURE ACS DCOS CLUSTER SCRIPT 
################################
#
# Description: Executes the steps needed on ACS DCOS
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
# Contact:  
#
#################################

ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

rgExists=$(az group list | grep -i $(prop 'resourceGroup'));
nameExists=$(az network public-ip list | grep -i dcos-master-ip-$(prop 'groupName')-mgmt);

cat acs-dcos-deploy.json | sed 's/XXX_USER_XXX/'$(prop 'sshuser')'/g' | sed 's/XXX_AGENTVMSIZE_XXX/'$(prop 'agentVmSize')'/g' | sed 's/XXX_MASTERCOUNT_XXX/'$(prop 'mastercount')'/g' |  sed 's/XXX_AGENTCOUNT_XXX/'$(prop 'agentcount')'/g' | sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' > template.json;

#cat acs-dcos-deploy.json | sed 's/XXX_USER_XXX/'$(prop 'sshuser')'/g' | sed 's/XXX_AGENTVMSIZE_XXX/'$(prop 'agentVmSize')'/g' | sed 's/XXX_MASTERCOUNT_XXX/'$(prop 'mastercount')'/g' |  sed 's/XXX_AGENTCOUNT_XXX/'$(prop 'agentcount')'/g' | sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' | sed 's/XXX_PUBLICKEY_XXX/'$(prop 'publicKey')'/g' > template.json;


if [ "$rgExists" == "" ]
then
  #azure group create $(prop 'resourceGroup') -l $(prop 'region');
  az group create --location $(prop 'region') --name $(prop 'resourceGroup')
else
  echo "ResourceGroup $(prop 'resourceGroup') already exists, using existing group...";
fi

echo $nameExists;

if  [ "$nameExists" == "" ]
then
  #azure group deployment create -f template.json "$(prop 'resourceGroup')";
  az group deployment create --resource-group $(prop 'resourceGroup') --name $(prop 'groupName') --template-file template.json
else
  echo "name $(prop 'groupName') already exists";
  exit 1
fi