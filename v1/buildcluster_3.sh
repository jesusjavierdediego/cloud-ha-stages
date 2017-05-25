#!/bin/bash

##########################################
#
# Name:        buildcluster_3.sh
# Description: Build a public LB and NSG rule on ACS DCOS
# Contact:     
#
##########################################

ENV=${1:-cit}

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
  azure network lb rule create -g $(prop 'resourceGroup') --lb-name  $lbName -n haproxy -p tcp -f 9090 -b 9090

  nsgName=$(azure network nsg list -g $(prop 'resourceGroup')| grep agent | grep public | awk '{print $2}')
  azure network nsg rule create -g $(prop 'resourceGroup') -a $nsgName -n haproxy-rule -c Allow -p Tcp -r Inbound -y 410 -f Internet -u 9090
  exit 0
fi
