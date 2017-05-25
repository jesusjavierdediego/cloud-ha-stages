#!/bin/bash

##########################################
#
# Name:        buildcluster_2.sh
# Description: Open a SSH tunnel on ACS DCOS
# Contact:     
#
##########################################


ENV=${1:-cit}

function prop {
    grep "${1}" env/${ENV}.properties|cut -d'=' -f2
}

sudo ssh -i $(prop 'keyPath') -v -o ExitOnForwardFailure=yes -fNL $(prop 'originPort'):localhost:$(prop 'destinationPort') -p 2200 -A $(prop 'sshuser')@$(prop 'groupName')-mgmt.northeurope.cloudapp.azure.com && exit
#sudo -E ssh -i ~/.ssh/id_rsa_stages -F ~/.ssh/config -l $USER jenkins -v -o ExitOnForwardFailure=yes -fNL 80:localhost:80 -p 2200 -A bureau_user@fsgbureauspcit-mgmt.northeurope.cloudapp.azure.com && exit
