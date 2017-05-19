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
# 
#
#################################

# 1-Declare variables
resourceGroup="FSG_BureauSP_HAStage_CIT";
region="northeurope";
sshuser="bureau_user";
mastercount=1;
agentcount=2;
groupName="fsgbureauspcit";
agentVmSize="Standard_D3";
rgExists=$(az group list | grep -i $resourcegroup);
nameExists=$(az network public-ip list | grep -i dcos-master-ip-$groupName-mgmt);

cat acs-dcos-deploy.json | sed 's/XXX_USER_XXX/'$sshuser'/g' | sed 's/XXX_AGENTVMSIZE_XXX/'$agentVmSize'/g' | sed 's/XXX_MASTERCOUNT_XXX/'$mastercount'/g' | sed 's/XXX_AGENTCOUNT_XXX/'$agentcount'/g' | sed 's/XXX_NAME_XXX/'$groupName'/g' > template.json;



if [ "$rgExists" == "" ]
then
  azure group create $resourceGroup -l $region;
else
  echo "resourcegroup $resourceGroup already exists, using existing group...";
fi

echo $nameExists;

if  [ "$nameExists" == "" ]
then
  azure group deployment create -f template.json $resourceGroup;
else
  echo "name $groupName already exists";
  exit 1
fi

# Set dcos CLI to the host
# sleep 10
# sudo ssh -i /home/jdediego/.ssh/id_rsa_stages -v -o ExitOnForwardFailure=yes -fNL 80:localhost:80 -p 2200 -A bureau_user@fsgbureauspcit-mgmt.northeurope.cloudapp.azure.com;

#dcos config set core.dcos_url http://localhost;
