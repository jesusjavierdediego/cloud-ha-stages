#!/bin/bash

ssh-keygen -f "/home/administrator/.ssh/known_hosts" -R [fsgbureauspqat2-mgmt.northeurope.cloudapp.azure.com]:2200
ssh -o StrictHostKeyChecking=no -i shared/privateKey -v -fNL 8089:localhost:80 -p 2200 -A fsgbureauspqat2-mgmt.northeurope.cloudapp.azure.com