#!/bin/bash

####################################################################################
#
# What: This script will run in the DC/OS admin pool to add the private key neeeded to
# mount the volume with the docker registry key
# Contact: FSG SRE Team     
#
####################################################################################

sudo apt-get install spawn --force-yes;

sudo apt-get install yes --force-yes;

sudo apt-get install expect --force-yes;

sudo apt-get install jq --force-yes;

cd shared;

chmod +x ssh-add-pass.sh

chmod 600 privateKey;

./ssh-add-pass.sh privateKey passFile

yes | ./mountShares.sh
