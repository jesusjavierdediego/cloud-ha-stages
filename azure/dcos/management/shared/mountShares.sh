#!/bin/bash

# Install jq used for the next command
# sudo apt-get install jq

# Create the local folder that will contain our share
if [ ! -d "/mnt/fsghaenvironments" ]; then sudo mkdir -p "/mnt/fsghaenvironments" ; fi

# Mount the share on the current vm (master)
sudo mount -t cifs //haenvironments.file.core.windows.net/fsghaenvironments /mnt/fsghaenvironments -o vers=3.0,username=haenvironments,password=cSnky2y4eXuYy0jHZshDIykSBxnq7fcIZR4p35f8nv6Imz+0UXHrAn1PsM4NbjNXuJB3sHngsKFdsyk2M8IZ5A==,dir_mode=0777,file_mode=0777

# Get the IP address of each node using the mesos API and store it inside a file called nodes
curl http://leader.mesos:1050/system/health/v1/nodes | jq '.nodes[].host_ip' | sed 's/\"//g' | sed '/172/d' > nodes

# From the previous file created, run our script to mount our share on each node
cat nodes | while read line
  do
    ssh `whoami`@$line -o StrictHostKeyChecking=no -i privateKey < ./cifsMount.sh
    done
