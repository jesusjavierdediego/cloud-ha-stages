
# Authentication into my ACR
docker login fsgregistry.azurecr.io -u fsgregistry -p SDVHXC=M/VaisP3g9rUx=TP1xQ6jiTew

# Tar the contains of the .docker folder
cd ~
tar czf docker.tar.gz .docker

# Upload the tar archive in the fileshare
az storage file upload -s fsghaenvironments --account-name haenvironments --account-key cSnky2y4eXuYy0jHZshDIykSBxnq7fcIZR4p35f8nv6Im --source docker.tar.gz