#!/bin/bash

##########################################
#
# Name:        deployAppsToCluster.sh
# Description: Deploys a docker image on the ACS DCOS cluster
# Contact:     
#
##########################################
ENV=${1:-qatsp}

function prop {
    grep "${1}" ~/Dropbox/cloud-ha-stages/env/demo.properties|cut -d'=' -f2
}

# config loadbalancer for app
lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name $(prop 'demoapp5.name')  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port $(prop 'demoapp5.serviceport') --backend-pool-name dcos-agent-pool-$id --backend-port $(prop 'demoapp5.serviceport') 


# config network security
nsgName=$(azure network nsg list -g $(prop 'resourceGroup') | grep agent | grep public | awk '{print $2}')
az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name $(prop 'demoapp5.name')-rule --access Allow --protocol Tcp --direction Inbound --priority $(prop 'demoapp5.rulenr') --source-address-prefix Internet  --destination-port-range $(prop 'demoapp5.serviceport')


#dcos marathon app add ~/Dropbox/cloud-ha-stages/descriptors/demo/microservice2.json

dcos marathon app add ~/Dropbox/cloud-ha-stages/descriptors/demo/microservice1.json