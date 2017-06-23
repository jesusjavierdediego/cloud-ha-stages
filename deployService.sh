#!/bin/bash

##########################################
#
# What:        Deploys a FxMS image on the ACS DCOS environment
# Notes: The parameters to be passed are:
# 1- The name of the stage/enviornment (qat, qatsp, uat, uatsp, etc) to match the *.properties file
# 2- The name of the service. It is the name of the image in the registry.
# 3- Number of instances/containers of the service (default: 2)
# 4- Number of the version of the service
# 5- External port for the service. The container internal port will be mapped to this port. 
# 6- External port for external debug (default: 8000)
# 7 -Priority of the rule in the NSG
# Contact:     
#
# ./deployService.sh qatsp bureaumobileweb bmwsp 1 0.1.99-SNAPSHOT 10003 8000 1003
##########################################
STAGE=${1}
SERVICENAME=${2}
APPNAME=${3}
INSTANCES=${4:-2}
VERSION=${5}
SERVICEPORT=${6}
DEBUGPORT=${7:-8000}
PRIORITY=${8}


function prop {
    grep "${1}" env/${STAGE}.properties|cut -d'=' -f2
}

# 1-Replace values in the service descriptor
cat descriptors/bureau/templates/${SERVICENAME}.json \
| sed 's/XXX_STAGE_XXX/'${STAGE}'/g'  \
| sed 's/XXX_PROFILE_XXX/'$(prop 'profile')'/g'  \
| sed 's/XXX_VERSION_XXX/'${VERSION}'/g'  \
| sed 's/XXX_INSTANCES_XXX/'${INSTANCES}'/g'  \
| sed 's/XXX_SERVICEPORT_XXX/'${SERVICEPORT}'/g'  \
| sed 's/XXX_DEBUGPORT_XXX/'${DEBUGPORT}'/g'  \
| sed 's/XXX_APPNAME_XXX/'${APPNAME}'/g'  \
> descriptors/bureau/${SERVICENAME}-deploy.json

lbElements=`az network lb list --resource-group $(prop 'resourceGroup') | jq '. | length'`

for (( lbId=0; lbId<$lbElements; lbId++ ))
do
    lbName=`az network lb list  --resource-group $(prop 'resourceGroup') | jq '.['$lbId'].name'`
    lbName=`echo $lbName | tr "\"" "\n"`
    id=`echo $lbName | cut -d '-' -f4`   
    if [[ $lbName == *"agent"* ]]; then
        az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name ${SERVICENAME}  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port ${SERVICEPORT} --backend-pool-name dcos-agent-pool-$id --backend-port ${SERVICEPORT}
        echo "Rule Configured for: "$lbName" and "$SERVICENAME
    else
        echo "LB: "$lbName" is not agent, rule not configured"
    fi    

done

#azure group show $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//'
# 2-config loadbalancer for the service
#lbName=$(az network lb --resource-group $(prop 'resourceGroup') | grep -i lb | grep agent | grep Name | sed 's/^.*[:][ ]//')
#for id in `echo $lbName | tr "-" "\n"`; do echo $id; done
#az network lb rule create --resource-group $(prop 'resourceGroup') --lb-name $lbName --name ${SERVICENAME}  --protocol tcp --frontend-ip-name dcos-agent-lbFrontEnd-$id --frontend-port ${SERVICEPORT} --backend-pool-name dcos-agent-pool-$id --backend-port ${SERVICEPORT} 

# 3-config network security
nsgElements=`az network nsg list --resource-group $(prop 'resourceGroup') | jq '. | length'`

for (( nsgId=0; nsgId<$nsgElements; nsgId++ ))
do
    nsgName=`az network nsg list  --resource-group $(prop 'resourceGroup') | jq '.['$nsgId'].name'`
    nsgName=`echo $nsgName | tr "\"" "\n"`
    if [[ $nsgName == *"agent"* ]]; then
        az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name ${SERVICENAME}-rule --access Allow --protocol Tcp --direction Inbound --priority ${PRIORITY} --source-address-prefix Internet  --destination-port-range ${SERVICEPORT}
        echo "Rule Configured for: "$nsgName" and "$SERVICENAME
    else
        echo echo "NSG: "$nsgName" is not agent, rule not configured"
    fi    

done

#nsgName=$(azure network nsg list -g $(prop 'resourceGroup') | grep agent | grep public | awk '{print $2}')
#az network nsg rule create --resource-group $(prop 'resourceGroup') --nsg-name $nsgName --name ${SERVICENAME}-rule --access Allow --protocol Tcp --direction Inbound --priority ${PRIORITY} --source-address-prefix Internet  --destination-port-range ${SERVICEPORT}

# 4-deploy service
dcos marathon app add descriptors/bureau/${SERVICENAME}-deploy.json