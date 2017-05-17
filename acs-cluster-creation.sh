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
lbInstall=`dcos package list | grep -i marathon-lb`
nsgName=$(azure network nsg list -g $resourcegroup| grep agent | grep public | awk '{print $2}')
lbName=$(azure group show $resourcegroup | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')

# 2-Check parameters
if [ "$#" -ne 5 ]
then
  echo "please provide the following parameters: "
  echo "- resourceGroup"
  echo "- region"
  echo "- sshuser"
  echo "- agentcount"
  echo "- groupName"
  exit 1
fi

resourceGroup=$1
region=$2
sshuser=$3
agentcount=$4
groupName=""
rgExists=$(azure group list | grep -i $resourceGroup) 
nameExists=$(azure network public-ip list | grep -i dcos-master-ip-$groupName-mgmt)

cat acs-mesos-deploy.json | sed 's/XXX_USER_XXX/'$sshuser'/g' | sed 's/XXX_AGENTCOUNT_XXX/'$agentcount'/g' | sed 's/XXX_NAME_XXX/'$groupName'/g' >template.json


# 3-Set the proper group name according to the RG/environment
if [ "$resourceGroup" == "FSG_BureauSP_HAStage_CIT" ]
then
  $groupName = "fsgbureauspcit"
else if [ "$resourceGroup" == "FSG_BureauSP_HAStage_QAT" ]
then
  $groupName = "fsgbureauspqat"
else if [ "$resourceGroup" == "FSG_BureauSP_HAStage_UAT" ]
then
  $groupName = "fsgbureauspuat"
else if [ "$resourceGroup" == "FSG_BureauSP_HAStage_PRD" ]
then
  $groupName = "fsgbureauspprd"
else
  echo "Resource Group $resourceGroup is not valid. Please check it out with availabe options."
fi


# 4-Create RG
if [ "$rgExists" == "" ]
then
  az group create --name $resourceGroup --location $region
else
  echo "resourcegroup $resourceGroup already exists, using existing group..."
fi


# 5-Create Cluster
echo $nameExists
if  [ "$nameExists" == "" ]
then
  # azure group deployment create -f template.json $resourceGroup
  az group deployment create -g $resourceGroup -n $groupName --template-file ./azuredeploy.json --parameters @azuredeploy.parameters.json
else
  echo "name $groupName already exists"
  exit 1
fi


# Open SSH tunnel

# Set dcos CLI to locahost

# only install if not already installed
lbInstall=`dcos package list | grep -i marathon-lb`
if [ "$lbInstall" == "" ]
then
  dcos package install marathon-lb

  lbName=$(azure group show $resourcegroup | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
  az network lb rule create --resource-group $resourcegroup --lb-name  $lbName --name haproxy --protocol tcp --frontend-port 9090 --backend-port 9090

  nsgName=$(azure network nsg list -g $resourcegroup| grep agent | grep public | awk '{print $2}')
  az network nsg rule create --resource-group $resourcegroup --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet --destination-port-range 9090
  exit 0
fi