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

PROPERTY_FILE=env/general.properties

function propGeneral {
   PROP_KEY=$1
   PROP_VALUE=`cat $PROPERTY_FILE | grep "$PROP_KEY" | cut -d'=' -f2`
   echo $PROP_VALUE
}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

publicKey=$(< $(prop 'publicKey'))
rgExists=$(az group list | grep -i $(prop 'resourceGroup'));
nameExists=$(az network public-ip list | grep -i dcos-master-ip-$(prop 'groupName')-mgmt);


cat acs/azuredeploy.parameters.template.json \
| sed 's/XXX_SUBSCRIPTION_XXX/'$(propGeneral 'subscription')'/g' \
| sed 's/XXX_VNETRG_XXX/'$(propGeneral 'vnetrg')'/g' \
| sed 's/XXX_VNET_XXX/'$(propGeneral 'mainvnet')'/g' \
| sed 's/XXX_REGION_XXX/'$(prop 'region')'/g' \
| sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' \
| sed 's/XXX_FIRSTMASTERIP_XXX/'$(prop 'firstConsecutiveStaticIP')'/g' \
| sed 's/XXX_MASTERSUBNET_XXX/'$(prop 'subnet_master')'/g' \
| sed 's/XXX_AGENTSUBNET_XXX/'$(prop 'subnet_agent')'/g' \
| sed 's/XXX_AGENTVMSIZE_XXX/'$(prop 'agentVmSize')'/g' \
| sed 's/XXX_MASTERCOUNT_XXX/'$(prop 'mastercount')'/g' \
| sed 's/XXX_AGENTCOUNT_XXX/'$(prop 'agentcount')'/g' \
| sed 's/XXX_USER_XXX/'$(prop 'sshuser')'/g' \
| sed "s|XXX_PUBLICKEY_XXX|$publicKey|" \
> acs/azuredeploy.parameters.json;


if [ "$rgExists" == "" ]
then
  az group create --location $(prop 'region') --name $(prop 'resourceGroup')
else
  echo "ResourceGroup $(prop 'resourceGroup') already exists, using existing group...";
fi

echo $nameExists;

if  [ "$nameExists" == "" ]
then
  az group deployment create \
  --resource-group $(prop 'resourceGroup') \
  --name $(prop 'groupName') \
  --template-file  acs/azuredeploy.json \
  --parameters  acs/azuredeploy.parameters.json
else
  echo "name $(prop 'groupName') already exists";
  exit 1
fi