#!/bin/bash

resourceGroup="FSG_BureauSP_HAStage_CIT";
region="northeurope";
sshuser="bureau_user";
mastercount=1;
agentcount=2;
groupName="fsgbureauspcit";
agentVmSize="Standard_D3";

# 6-Create LB for public IP and NSG rules
lbInstall=`dcos package list | grep -i marathon-lb`;
if [ "$lbInstall" == "" ]
then
  dcos package install marathon-lb --yes;

  lbName=$(azure group show --name FSG_BureauSP_HAStage_CIT | grep -i dcos-agent-lb | grep Name | sed 's/^.*[:][ ]//');
  az network lb rule create --resource-group FSG_BureauSP_HAStage_CIT --lb-name  $lbName --name haproxy --backend-pool-name backendPool  --frontend-ip-name frontendIP  --protocol Tcp   --frontend-port 9090 --backend-port 9090;

  nsgName=$(azure network nsg list --resource-group FSG_BureauSP_HAStage_CIT| grep dcos-agent-public-nsg | awk '{print $2}');
  az network nsg rule create --resource-group FSG_BureauSP_HAStage_CIT --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet --destination-port-range 9090;
  exit 0;
fi