#!/bin/bash

##########################################
#
# What:        Deploys a FxMS image on the ACS DCOS environment
# Notes: The parameters to be passed are:
# 1- Name of the service
# 2- Target environment and profile for configuration
# 3- Number of instances/containers of the service (default: 2)
# 4- Number of the version of the service
# 5- External port for the service. The container internal port will be mapped to this port. 
# 6- External port for external debug (default: 8000)
# 7 -Priority of the rule in the NSG
# Contact:     
#
##########################################
STAGE=${1}
SERVICENAME=${2}
PROFILE=${3}
INSTANCES=${4:-2}
VERSION=${5}
SERVICEPORT=${6}
DEBUGPORT=${7:-8000}
PRIORITY=${8}

function prop {
    grep "${1}" env/${STAGE}.properties|cut -d'=' -f2
}

# 1-Replace values in the service descriptor
cat descriptors/bureau/templates/${SERVICENAME}.json | sed 's/XXX_PROFILE_XXX/'${PROFILE}'/g' | sed 's/XXX_VERSION_XXX/'${VERSION}'/g' | sed 's/XXX_INSTANCES_XXX/'${INSTANCES}'/g' | sed 's/XXX_SERVICEPORT_XXX/'${SERVICEPORT}'/g' | sed 's/XXX_DEBUGPORT_XXX/'${DEBUGPORT}'/g' > descriptors/bureau/${SERVICENAME}-deploy.json

# 2-config loadbalancer for the service
lbName=$(azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name ${SERVICENAME}  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port ${SERVICEPORT} --backend-pool-name dcos-agent-pool-$id --backend-port ${SERVICEPORT} 

# 3-config network security
nsgName=$(azure network nsg list -g $(prop 'resourceGroup') | grep agent | grep public | awk '{print $2}')
az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name ${SERVICENAME}-rule --access Allow --protocol Tcp --direction Inbound --priority ${PRIORITY} --source-address-prefix Internet  --destination-port-range ${SERVICEPORT}

# 4-deploy service
dcos marathon app add descriptors/bureau/${SERVICENAME}-deploy.json