# Cloud IT PLatform HA Stages/Environments
<p align="center">
  <img src="https://acomblogimages.blob.core.windows.net/media/Default/Windows-Live-Writer/acslogo.png" width="300"/>
  <img src="https://mesosphere.com/wp-content/uploads/2016/04/logo-horizontal-styled-400x300@2x.png" width="300"/>
</p>

## Description
This repository stores the Scripts for the creation of Azure ACS clusters using DC/OS, including:

- a scaleset of x amount of machines/nodes for the master (x is parameterized value)
- a scaleset of x amount of machines/nodes for the agents  (x is parameterized value)
- an internal azure loadbalancer 
- an external azure loadbalancer 
- network security groups for securing differents vlans
- a public ip adress for accessing the master node(s)
- a public ip adress for accessing the agent node(s)

These scripts use AZ CLI v2 and ARM.
Current used version of DC/OS is 1.9.

## Requirements
Azure account, valid user, valid key pair for cluster access.
You need to be logged in to Azure to execute the scripts.

## Steps
### Preparation of properties
Edit the files in the "env" directory. You'll find there the properties files for the pre-defined environments. If you need to add new environments create new files in this directory.
The main properties groups are:
1-Azure properties (Resource Group, cluster name, location zone)
2-User Properties to login to the cluster, including paths to public and private keys
3-Cluster properties. Number of nodes (masters and agents), VM size
4-SSH tunnel ports
5-Specific properties. For instance, the Spring profile to get the app configurations from the Configuration Server

### Cluster VNET
All clusters created with ACS in the CITP must be created in the standard primary VNET "FSG_NET1" for control and security purposes.
There are pairs of subnets created for each specific environment. For instance:

fsg_subnet_stages_qatsp_master 172.16.3.0/24
fsg_subnet_stages_qatsp_agents 172.16.4.0/24

fsg_subnet_stages_uatsp_master 172.16.5.0/24
fsg_subnet_stages_uatsp_agents 172.16.6.0/24

fsg_subnet_stages_prdsp_master 172.16.7.0/24
fsg_subnet_stages_prdsp_agents 172.16.8.0/24

Each DC/OS cluster needs two subnets, for master and agent nodes. Each subnet has a different IP range.
You will need to create a new pair of subnets in the FSG_NET1 VNET for new environments.
You can re-use the templates in this repository for new environments.

### Create the cluster

#### STEP 1
Script: buildcluster_1
Execute the script buildcluster_1 to run the steps needed on ACS DC/OS.
You will need to provide some par
This action will perform:
1- Create the Resource Group
2- Create the ACS DC/OS cluster

#### STEP 2
Script: buildcluster_2
Execute the script buildcluster_2 to communicate to the new cluster
It is a SSH tunnel to port 80. You should be able to connect to the DC/OS cluster dashboard through
http://localhost
http://localhost/marathon
http://localhost/mesos

#### STEP 3
Script: buildcluster_3
1- Installs external and internal loadbalancers
2- Create network loadbalancer rules (also for loadbalancer if needed)
3- Create network security group rules (also for loadbalancer if needed)

You should be able to connect through your browser to the cluster. For instance:
HA Proxy: http://<clusterName>-agents.<locationZone>.cloudapp.azure.com:9090/haproxy?stats
Internal Monitor:  http://localhost/service/weavescope

#### STEP 4
Script: buildcluster_4
To provide the cluster login data to the private image registry and other files we need to mount a shared drive in all the nodes in the cluster. This script sends the private key to the admin node and connect to it to ru the script buildcluster_4b that mounts the shared drive.
The services will include the tar.gz file in the descriptor to be found in every node and will be used to connect to the private registry:

"uris": [
    "file:///mnt/fsghaenvironments/docker.tar.gz"
],

### Deploy services
The applications are deployed in DC/OS as "services" with a certain number of instances, mapped ports, commands, etc.
The descriptor of the service is a JSON file specific for each application.
The JSON files are stored into a system/project specific directory (e.g. "bureau").
Add new JSON descriptor files to be able to deploy new applications as DC/OS services.

The main factors to be considered for parameterization are:

a) Is the service publicly accessible or not?
b) How many instances (simultaneously running containers) should be the average?
c) Is the service stateless or stateful?

Prepare your JSON descriptors according to this information.

Internal stateless service:
"labels": {
    "HAPROXY_GROUP": "internal"
  }

External stateless service:
"labels": {
    "HAPROXY_GROUP": "external"
  }

Stateful external service (redirect requests to the same container according to source IP and protocol):
"labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_STICKY": "true"
}

Use the script deployService.sh passing the next parameters:
1-The name of the stage/enviornment (qat, qatsp, uat, uatsp, etc) to match the *.properties file
2-The name of the service. It is the name of the image in the registry.
3-Number of instances/containers of the service (default: 2)
4-Number of the version of the service
5-External port for the service. The container internal port will be mapped to this port. 
6-External port for external debug (default: 8000)
7-Priority of the rule in the NSG


## Resources
https://docs.microsoft.com/en-us/cli/azure/acs/dcos
https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.md
https://github.com/Azure/acs-engine/blob/master/docs/dcos.md
https://dcos.io/docs/1.9
https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md


