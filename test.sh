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



# 4-Create RG
if [ "$rgExists" == "" ]
then
  az group create --name $resourceGroup --location $region;
else
  echo "resourcegroup $resourceGroup already exists, using existing group...";
fi


# 5-Create Cluster
echo $nameExists;
if  [ "$nameExists" == "" ]
then
  # azure group deployment create -f template.json $resourceGroup
  az group deployment create --resource-group $resourceGroup --name $groupName --template-file ./template.json;

  # KEEP FOR ENVIRONMENT PARAMETERS (passing variable avlues as params in the json file)
  # --parameters @azuredeploy.parameters.json
else
  echo "name $groupName already exists";
  exit 1;
fi

# Set dcos CLI to the host
sudo ssh -i /home/jdediego/.ssh/id_rsa_azure -v -fNL 80:localhost:80 -p 2200 bureau_user@fsgbureauspcit-mgmt.northeurope.cloudapp.azure.com


# 6-Create LB for public IP and NSG rules
lbInstall=`dcos package list | grep -i marathon-lb`;
if [ "$lbInstall" == "" ]
then
  dcos package install marathon-lb;

  lbName=$(az group show $resourcegroup | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//');
  az network lb rule create --resource-group $resourcegroup --lb-name  $lbName --name haproxy --protocol tcp --frontend-port 9090 --backend-port 9090;

  nsgName=$(az network nsg list --resource-group $resourcegroup| grep agent | grep public | awk '{print $2}');
  az network nsg rule create --resource-group $resourcegroup --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet --destination-port-range 9090;
  exit 0;
fi