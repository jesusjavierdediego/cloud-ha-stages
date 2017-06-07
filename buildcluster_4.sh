#!/bin/bash

################################
# AZURE ACS DCOS CLUSTER SCRIPT 
################################
#
# Description: Executes the steps needed on ACS DCOS
# Content:
#    - a scaleset of x amount of machines/nodes for the master (x is parameterized value)
#    - a scaleset of x amount of machines/nodes for the agents  (x is parameterized value)
#    - an internal azure loadbalancer 
#    - an external azure loadbalancer 
#    - network security groups for securing differents vlans
#    - a public ip adress for accessing the master node(s)
#    - a public ip adress for accessing the agent node(s)
# Steps:
#   - Installs a loadbalancer
#   - create network loadbalancer rule (also for loadbalancer if needed)
#   - create network security group rule (also for loadbalancer if needed)
# Contact:  
#
#################################

ENV=${1:-qat}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

key=$(cat env/publicKey)
echo "start"
echo $key
echo "end"
# cat acs-dcos-deploy.json | sed -n 's/XXX_PUBLICKEY_XXX/'`"$key"`'/g' | sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' > template2.json;

# cat acs-dcos-deploy.json | sed 's/XXX_PUBLICKEY_XXX/'`"$key"`'/g' | sed 's/XXX_NAME_XXX/'$(prop 'groupName')'/g' > template2.json;
cat acs-dcos-deploy.json | sed "s|a/XXX_PUBLICKEY_XXX/ dumb string|$key|g" >  template2.json