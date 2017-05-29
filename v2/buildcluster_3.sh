#!/bin/bash

##########################################
#
# Name:        buildcluster_3.sh
# Description: Build a public LB and NSG rule on ACS DCOS
# Contact:     
#
##########################################

ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

dcos config set core.dcos_url http://localhost;

lbInstall=`dcos package list | grep -i marathon-lb`
weavescopeInstall=`dcos package list | grep -i weavescope`
weavescopeProbeInstall=`dcos package list | grep -i weavescope-probe`
if [ "$lbInstall" == "" ] && [ "$weavescopeInstall" == "" ] && [ "$weavescopeProbeInstall" == "" ]
then
  dcos package install weavescope --yes;
  dcos package install weavescope-probe --options=weavescope-probe.json  --yes;
  dcos package install marathon-lb --yes;

  lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
  for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
  echo "The ID is : $id"
  az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name haproxy  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port 9090 --backend-pool-name dcos-agent-pool-$id --backend-port 9090   

  nsgName=$(azure network nsg list -g $(prop 'resourceGroup')| grep agent | grep public | awk '{print $2}')
  az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet  --destination-port-range 9090

  exit 0
fi
