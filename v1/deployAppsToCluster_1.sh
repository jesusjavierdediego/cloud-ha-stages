#!/bin/bash

##########################################
#
# Name:        deployAppsToCluster.sh
# Description: Deploys a docker image on the ACS DCOS cluster
# Contact:     
#
##########################################
ENV=${1:-cit}
APP=${2:-redis}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}


# deploy app
dcos marathon app add $(prop 'jsonappfile')

# config loadbalancer for app
lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
appName=`echo $(prop 'jsonappfile') | sed 's/.json//'`
azure network lb rule create -g $(prop 'resourceGroup') -l $lbName -n $appName -p tcp -f $(prop 'serviceport') -b $(prop 'serviceport')

# config network security
nsgName=$(azure network nsg list -g $(prop 'resourceGroup') | grep agent | grep public | awk '{print $2}')
azure network nsg rule create -g $(prop 'resourceGroup') -a $nsgName -n $appName-rule -c Allow -p Tcp -r Inbound -y $(prop 'rulenr') -f Internet -u $(prop 'serviceport') 
