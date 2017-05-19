#!/bin/bash

resourceGroup="FSG_BureauSP_HAStage_CIT"

# 6-Create LB for public IP and NSG rules
lbInstall=`dcos package list | grep -i marathon-lb`
if [ "$lbInstall" == "" ]
then
  dcos package install marathon-lb --yes;

  lbName=$(azure group show $resourceGroup | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
  azure network lb rule create -g $resourceGroup --lb-name  $lbName -n haproxy -p tcp -f 9090 -b 9090

  nsgName=$(azure network nsg list -g $resourceGroup| grep agent | grep public | awk '{print $2}')
  azure network nsg rule create -g $resourceGroup -a $nsgName -n haproxy-rule -c Allow -p Tcp -r Inbound -y 410 -f Internet -u 9090
  exit 0
fi
