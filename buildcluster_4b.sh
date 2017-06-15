#!/bin/bash

##########################################
#
# What: This script will run in the master node
# in the cluster to add the private key neeeded to
# mount the volume with the docker registry key
# Contact: FSG SRE Team     
#
##########################################

sudo apt-get install spawn --force-yes;

sudo apt-get install yes --force-yes;

sudo apt-get install expect --force-yes;

sudo apt-get install jq --force-yes;

cd dockerRegistry;

chmod +x ssh-add-pass.sh

chmod 600 privateKey;

./ssh-add-pass.sh privateKey passFile

yes | ./mountShares.sh
