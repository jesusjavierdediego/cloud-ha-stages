# Cloud IT PLatform HA Stages/Environments
<p align="center">
  <img src="https://acomblogimages.blob.core.windows.net/media/Default/Windows-Live-Writer/acslogo.png" width="350"/>
  <img src="https://mesosphere.com/wp-content/uploads/2016/04/logo-horizontal-styled-400x300@2x.png" width="350"/>
</p>

## Description
Scripts for creation of Azure ACS clusters using DCOS 

- a scaleset of x amount of machines/nodes for the master (x is parameterized value)
- a scaleset of x amount of machines/nodes for the agents  (x is parameterized value)
- an internal azure loadbalancer 
- an external azure loadbalancer 
- network security groups for securing differents vlans
- a public ip adress for accessing the master node(s)
- a public ip adress for accessing the agent node(s)


## Requirements
Azure account, valid user, valid keys.
You need to be logged in to Azure to execute the scripts.

## Steps
### Create the cluster
Execute the script buildcluster_1 to run the steps needed on ACS DC/OS
- Create the Resource Group
- Create the ACS DC/OS cluster

Execute the script buildcluster_2 to communicate to the new cluster
It is a SSH tunnel to port 80

Script buildcluster_2
- Installs external and internal loadbalancers
- Create network loadbalancer rules (also for loadbalancer if needed)
- Create network security group rules (also for loadbalancer if needed)

### Deploy services
The main factors for parameterization are:

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

Stateful external service:
"labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_STICKY": "true"
}


Use the script deployService.sh passing the next parameters:
- Name of the service
- Target environment and profile for configuration
- Number of instances/containers of the service (default: 2)
- Number of the version of the service
- External port for the service. The container internal port will be mapped to this port. 
- External port for external debug (default: 8000)
-Priority of the rule in the NSG




## Documentation
https://docs.microsoft.com/en-us/cli/azure/acs/dcos
https://dcos.io/docs/1.9


