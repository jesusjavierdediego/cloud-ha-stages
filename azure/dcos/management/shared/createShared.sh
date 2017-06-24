#!/bin/bash

####################################################################################
#
# What: This script will run in the DC/OS admin pool to add the private key neeeded to
# mount the volume with the docker registry key
# Contact: FSG SRE Team     
#
####################################################################################


sudo apt-get --yes install expect;

sudo apt-get --yes install jq;

cd shared;

chmod +x ssh-add-pass.sh;

chmod 600 privateKey;

./ssh-add-pass.sh privateKey

yes | ./mountShares.sh
