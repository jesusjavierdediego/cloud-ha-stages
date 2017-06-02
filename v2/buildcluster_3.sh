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

#lbInstall=`dcos package list | grep -i marathon-lb`
extLbInstall=`dcos package list | grep -i lb-external`
intLbInstall=`dcos package list | grep -i lb-internal`
weavescopeInstall=`dcos package list | grep -i weavescope`
weavescopeProbeInstall=`dcos package list | grep -i weavescope-probe`
#if [ "$lbInstall" == "" ] && [ "$weavescopeInstall" == "" ] && [ "$weavescopeProbeInstall" == "" ]
if [ "$extLbInstall" == "" ] && [ "$intLbInstall" == "" ] && [ "$weavescopeInstall" == "" ] && [ "$weavescopeProbeInstall" == "" ]
then
  dcos package install weavescope --yes;
  dcos package install weavescope-probe --options=descriptors/weavescope-probe.json  --yes;
  dcos package install marathon-lb --options=descriptors/lb-external-options.json --yes;
  dcos package install marathon-lb --options=descriptors/lb-internal-options.json --yes;

  lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
  for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
  echo "The ID is : $id"
  az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name haproxy  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port 9090 --backend-pool-name dcos-agent-pool-$id --backend-port 9090   

  nsgName=$(azure network nsg list -g $(prop 'resourceGroup')| grep agent | grep public | awk '{print $2}')
  az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name haproxy-rule --access Allow --protocol Tcp --direction Inbound --priority 410 --source-address-prefix Internet  --destination-port-range 9090

  exit 0
else
  echo "LBs and Monitors already installed?";
  echo "extLbInstall: $extLbInstall";
  echo "intLbInstall: $intLbInstall";
  echo "weavescopeInstall: $weavescopeInstall";
  echo "weavescopeProbeInstall: $weavescopeProbeInstall";
  exit 1
fi

