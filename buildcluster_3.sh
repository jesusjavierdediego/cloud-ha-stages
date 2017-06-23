#!/bin/bash

##########################################
#
# What: Build a public LB and NSG rule on ACS DCOS
# Contact:    FSG SRE Team 
#
##########################################

ENV=${1:-qatsp}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

dcos config set core.dcos_url http://localhost;

extLbInstall=`dcos package list | grep -i lb-external`
intLbInstall=`dcos package list | grep -i lb-internal`
weavescopeInstall=`dcos package list | grep -i weavescope`
weavescopeProbeInstall=`dcos package list | grep -i weavescope-probe`
msomsInstall=`dcos package list | grep -i msoms`


if [ "$extLbInstall" == "" ] && [ "$intLbInstall" == "" ] && [ "$weavescopeInstall" == "" ] && [ "$weavescopeProbeInstall" == "" ] && [ "$msomsInstall" == "" ]
then

  dcos package install weavescope --yes;
  dcos package install weavescope-probe --options=descriptors/cluster/weavescope-probe.json  --yes;
  dcos package install marathon-lb --options=descriptors/cluster/lb-external-options.json --yes;
  dcos package install marathon-lb --options=descriptors/cluster/lb-internal-options.json --yes;
  dcos package install msoms --options=descriptors/cluster/msoms-options.json --yes;

  lbElements=`az network lb list --resource-group $(prop 'resourceGroup') | jq '. | length'`

  for (( lbId=0; lbId<$lbElements; lbId++ ))
  do
      lbCompleteName=`az network lb list  --resource-group $(prop 'resourceGroup') | jq '.['$lbId'].name'`
      lbName=`echo $lbCompleteName | tr "\"" "\n"`
      id=`echo $lbName | cut -d '-' -f4`      
      
      echo "LB name is: $lbName"
      echo "The acs group id is: $id"
      az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name haproxy  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port 9090 --backend-pool-name dcos-agent-pool-$id --backend-port 9090   

  done

  nsgElements=`az network nsg list --resource-group $(prop 'resourceGroup') | jq '. | length'`

  for (( nsgId=0; nsgId<$nsgElements; nsgId++ ))
  do

      nsgName=`az network nsg list  --resource-group $(prop 'resourceGroup') | jq '.['$nsgId'].name'`
      nsgName=`echo $nsgName | tr "\"" "\n"`
      az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet  --destination-port-range 9090

  done
  
else

  lbElements=`az network lb list --resource-group $(prop 'resourceGroup') | jq '. | length'`

  for (( lbId=0; lbId<$lbElements; lbId++ ))
  do
      lbCompleteName=`az network lb list  --resource-group $(prop 'resourceGroup') | jq '.['$lbId'].name'`
      lbName=`echo $lbCompleteName | tr "\"" "\n"`
      id=`echo $lbName | cut -d '-' -f4`      
      
      echo "LB name is: $lbName"
      echo "The acs group id is: $id"
      az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name haproxy  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port 9090 --backend-pool-name dcos-agent-pool-$id --backend-port 9090   

  done

  nsgElements=`az network nsg list --resource-group $(prop 'resourceGroup') | jq '. | length'`

  for (( nsgId=0; nsgId<$nsgElements; nsgId++ ))
  do

      nsgName=`az network nsg list  --resource-group $(prop 'resourceGroup') | jq '.['$nsgId'].name'`
      nsgName=`echo $nsgName | tr "\"" "\n"`
      az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet  --destination-port-range 9090

  done

  exit 0

  echo "LBs and Monitors already installed?";
  echo "extLbInstall: $extLbInstall";
  echo "intLbInstall: $intLbInstall";
  echo "weavescopeInstall: $weavescopeInstall";
  echo "weavescopeProbeInstall: $weavescopeProbeInstall";
  echo "msomsInstall: $msomsInstall";
  exit 1
fi


