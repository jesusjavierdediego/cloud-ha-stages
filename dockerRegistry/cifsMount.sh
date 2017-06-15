#!/bin/bash

# Install the cifs utils, should be already installed
sudo apt-get update && sudo apt-get -y install cifs-utils

# Create the local folder that will contain our share
if [ ! -d "/mnt/fsghaenvironments" ]; then sudo mkdir -p "/mnt/fsghaenvironments" ; fi

# Mount the share under the previous local folder created
sudo mount -t cifs //haenvironments.file.core.windows.net/fsghaenvironments /mnt/fsghaenvironments -o vers=3.0,username=haenvironments,password=cSnky2y4eXuYy0jHZshDIykSBxnq7fcIZR4p35f8nv6Imz+0UXHrAn1PsM4NbjNXuJB3sHngsKFdsyk2M8IZ5A==,dir_mode=0777,file_mode=0777