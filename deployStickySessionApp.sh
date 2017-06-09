#!/bin/bash

##########################################
#
# Name:        deployAppsToCluster.sh
# Description: Deploys a docker image on the ACS DCOS cluster
# Contact:     
#
##########################################
ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}


# deploy app
dcos marathon app add descriptors/redis_demo.json
dcos marathon app add descriptors/sticky-sessions.json

# config loadbalancer for app
lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
az network lb probe create -g $(prop 'resourceGroup') --name $(prop 'demoapp4.probeStickySessionName') --lb-name $lbName --port $(prop 'demoapp4.serviceport') --protocol Http --path /
for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name $(prop 'demoapp4.name')  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port $(prop 'demoapp4.serviceport') --backend-pool-name dcos-agent-pool-$id --backend-port $(prop 'demoapp4.serviceport')  --load-distribution $(prop 'demoapp4.loadDistributionMode') --probe-name $(prop 'demoapp4.probeStickySessionName')

 
# config network security
nsgName=$(azure network nsg list -g $(prop 'resourceGroup') | grep agent | grep public | awk '{print $2}')
az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name $(prop 'demoapp4.name')-rule --access Allow --protocol Tcp --direction Inbound --priority $(prop 'demoapp4.rulenr') --source-address-prefix Internet  --destination-port-range $(prop 'demoapp4.serviceport')

