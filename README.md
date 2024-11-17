# DevOps Challenge

This is the Documentation for the Acklen Avenue DevOps Challenge

Before we begin let's address some things. 

- The challenge was done using Oracle Cloud Infrastructure since is the only cloud provider I have experience with. Let's translate some concept from one cloud to another.
- VPC in AWS = VCN in Oracle
- EC2 in AWS = Compute Instance (Virtual Machine) in Oracle
- Availability Zone (AZ) in AWS = Availability Domain (AD) in Oracle
- The content of this documentation is based on the official Oracle Documentation and the Oracle Cloud Infrastructure DevOps Professional Course

## Prerequsites

- You should have an Oracle Cloud Account.
- Log in to your account.
- You need to create a compartment to store all the resources.
- Open the Cloud Editor
- Click on **Terminal** and then on **New Terminal**
- Create a Directory to store all the content of the repository
- Download the repository.

## VCN

Access the VCN directory

```
cd VCN
```

The directory is comprised of three files. The ``` vcn.tf ```, ``` variables.tf ``` and ``` terraform.tfvars ```.

In the ``` variables.tf ``` we declare the variables that are going to be used for to create the infrastructure. 

```
variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}
```

The variables required are two. You need the compartment OCID where you want to store all the resources and the region. For the region is important to choose one that has at least 3 Availability Domains. For this challenge we are choosing the region of US West (Phoenix). 

In the ``` terraform.tfvars ``` is where we write the content of the variables.

```
compartment_id = "<Your_Compartment_OCID>"
region = "us-phoenix-1"
```

In the ``` vcn.tf ``` we specify the details of the VCN that we are going to create. Let's check each part.

- This section is the default that your terraform file should contain. It is also where we specify the region.

```
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
  required_version = ">= 1.0.0"
}

provider "oci" {
  region = var.region
}
```

- This section is where we specify all the details of the VCN we are going to create. 

```
#VCN
resource "oci_core_vcn" "vcn_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "VCN-DEVOPS-CHALLENGE" 
    cidr_blocks = ["10.0.0.0/16"]
}
```

- This section is where we create the public subnets. The two subnets should be placed in different availability domains.

```
#Public Subnet in AD 1
resource "oci_core_subnet" "subnet_1_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "PUBLIC-SUBNET-1-DEVOPS-CHALLENGE"
    vcn_id = oci_core_vcn.vcn_devops_challenge.id
    availability_domain = "fGuh:PHX-AD-1" #Availability Domain 1
    cidr_block = "10.0.0.0/24"
}

#Public Subnet in AD 2

resource "oci_core_subnet" "subnet_2_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "PUBLIC-SUBNET-2-DEVOPS-CHALLENGE"
    vcn_id = oci_core_vcn.vcn_devops_challenge.id
    availability_domain = "fGuh:PHX-AD-2" #Availability Domain 2
    cidr_block = "10.0.1.0/24"
}
```

-This is where we create the Internet Gateway and the route rules to allow access to the Internet.

```
#Internet Gateway
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_devops_challenge.id
  display_name   = "IGW"
}

#Route Table
resource "oci_core_default_route_table" "route_table" {
  compartment_id = var.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn_devops_challenge.default_route_table_id
  
  display_name = "Default-Route-Table"
  dynamic "route_rules" {
    for_each = [true]
    content {
      destination       = "0.0.0.0/0"
      description       = "Access to the Internet"
      network_entity_id = oci_core_internet_gateway.internet_gateway.id
    }
  }
}
```
With all this information we can create the resources. In the directory execute the terraform commands:

```
terrafom init
terraform plan
terraform apply
```

We go to the VCN section in the OCI, select the compartment and check if the VCN was created. We click on the VCN and see all the other resources created. 

We will need the OCID of the two subnets for the next section

Before we continue with the next section, we need to go to the security list and add manually some ingress and egress rules:

Ingress rules:

- Source CIDR: 0.0.0.0/0 Port: 80
- Source CIDR: 10.0.0.0/24 Port: 5000
- Source CIDR: 10.0.1.0/24 Port: 5000

Egress rules:

- Source CIDR: 10.0.0.0/24 Port: 5000
- Source CIDR: 10.0.1.0/24 Port: 5000

## Instances

Before we begin, we need to create an ssh-key pair in order for us to access the instances. We create the in the directory that we are currently working on:

```
ssh-keygen
```

In this section we create two compute instances (virtual machines). The instances will have the following characteristics:

- Operating System: Oracle Linux 8
- OCPU: 1
- RAM: 2 GB
- SHAPE: VM.Standard.A1.Flex (arm64 architecture)


We go to the INSTANCES directory

```
cd ..
cd INSTANCES
```

There are 3 files. Just like the previous section.

The ``` variables.tf ``` where we declare the variables. For this section we are going to declare more variables.

```
variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}

variable "image" {
  type = string
}

variable "sshkey" {
  type = string
}

variable "subnet_id_1" {
  type = string
}

variable "subnet_id_2" {
  type = string
}
```

In the ``` terraform.tfvars ``` is where we write the content of the variables. The "image" variable is to specify the image of the operating system which is Linux 8 and arm64 architecture and for the US West (Phoenix) region. Do not change this. It is from this website: https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/oracle-linux-8-10-aarch64-2024-09-30-0.htm

```
compartment_id = "<Your_Compartment_OCID>"
region = "us-phoenix-1"
image = "ocid1.image.oc1.phx.aaaaaaaaug4bu37fn6d6ezz7qfvfhqk4bch7gfujrmpyhofwergono3t7waa"
sshkey = "<Your_Public_shh_Key>"
subnet_id_1 = "<Your_Subnet_1_OCID>"
subnet_id_2 = "<Your_Subnet_2_OCID>"
```

In the ``` instances.tf ``` we specify the details of the Instances that we are going to create. Let's check each part.

- This section is the default that your terraform file should contain. It is also where we specify the region.

```
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
  required_version = ">= 1.0.0"
}

provider "oci" {
  region = var.region
}
```

- In this section we create the two instances in different subnets and availability domains.

```
#Instances 1
resource "oci_core_instance" "Instance-1-DEVOPS-CHALLENGE" {
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  availability_domain = "fGuh:PHX-AD-1"
  display_name        = "Instance-1-DEVOPS-CHALLENGE"

  source_details {
    source_id   = var.image
    source_type = "image"
  }

  dynamic "shape_config" {
    for_each = [true]
    content {
      #Optional
      memory_in_gbs = 2
      ocpus         = 1
    }
  }

  create_vnic_details {
    subnet_id = var.subnet_id_1
  }

  metadata = {
    ssh_authorized_keys = var.sshkey
    }
}

#Instances 2
resource "oci_core_instance" "Instance-2-DEVOPS-CHALLENGE" {
  compartment_id      = var.compartment_id
  shape               = "VM.Standard.A1.Flex"
  availability_domain = "fGuh:PHX-AD-2"
  display_name        = "Instance-2-DEVOPS-CHALLENGE"

  source_details {
    source_id   = var.image
    source_type = "image"
  }

  dynamic "shape_config" {
    for_each = [true]
    content {
      #Optional
      memory_in_gbs = 2
      ocpus         = 1
    }
  }

  create_vnic_details {
    subnet_id = var.subnet_id_2
  }

  metadata = {
    ssh_authorized_keys = var.sshkey
    }
}
```

We execute the terraform commands:

```
terraform init
terraform plan
terraform apply
```

We go to the Instances section of the OCI and check if the resources were created. We use the public ssh to access with ssh and using the private key to check it works. Copy the Private IP beacause you will need for the next section.

```
ssh -i "/path/to/private_key" opc@<Your_public_ip>
```

## Load Balancer

There are 3 files. Just like the previous section.

The `` variables.tf ``` where we declare the variables. For this section we are going to declare more variables.

```
variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_id_1" {
  type = string
}

variable "subnet_id_2" {
  type = string
}

variable "private_ip_1" {
  type = string
}

variable "private_ip_2" {
  type = string
}
```

In the ``` terraform.tfvars ``` is where we write the content of the variables.

```
compartment_id = "<Your_Compartment_OCID>"
region = "us-phoenix-1"
subnet_id_1 = "<Your_Subnet_1_OCID>"
subnet_id_2 = "<Your_Subnet_2_OCID>"
private_ip_1 = "<Your_Private_IP_1>"
private_ip_2 = "<Your_Private_IP_2>"
```

In the ``` load_balancer.tf ``` we specify the details of the VCN that we are going to create. Let's check each part.

- This section is the default that your terraform file should contain. It is also where we specify the region.

```
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
  required_version = ">= 1.0.0"
}

provider "oci" {
  region = var.region
}
```

- This section includes the general information of the Load Balancer

```
#Create the Load Balancer
resource oci_load_balancer_load_balancer LB-DEVOPS-CHALLENGE {
  compartment_id = var.compartment_id
  display_name = "LB-DEVOPS-CHALLENGE"
  ip_mode = "IPV4"
  is_private            = "false"
  is_request_id_enabled = "true"
  network_security_group_ids = [
  ]
  request_id_header = "X-Request-Id"
  shape = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = "10"
    minimum_bandwidth_in_mbps = "10"
  }
  subnet_ids = [
    var.subnet_id_1,
    var.subnet_id_2,
  ]
}
```

- Here you specify the characteristics of the backend set. The port needs to be 5000 since the node application that is going to be 

```
#Create the Backend set
resource oci_load_balancer_backend_set BS-DEVOPS-CHALLENGE {
  health_checker {
    interval_ms = "10000"
    port                = "5000"
    protocol            = "TCP"
    #response_body_regex = ""
    retries             = "3"
    #return_code         = "200"
    timeout_in_millis   = "3000"
    #url_path            = "/"
  }
  load_balancer_id = oci_load_balancer_load_balancer.LB-DEVOPS-CHALLENGE.id
  name             = "BS-DEVOPS-CHALLENGE"
  policy           = "ROUND_ROBIN"
}
```

- We add the two instance to the backend set. Remeber to open port 5000

```
#Adding Instance 1 to Backend set
resource oci_load_balancer_backend instance_1 {
  backendset_name  = oci_load_balancer_backend_set.BS-DEVOPS-CHALLENGE.name
  backup           = "false"
  drain            = "false"
  ip_address       = var.private_ip_1
  load_balancer_id = oci_load_balancer_load_balancer.LB-DEVOPS-CHALLENGE.id
  offline = "false"
  port    = "5000"
  weight  = "1"
}

#Adding Instance 2 to Backend set
resource oci_load_balancer_backend instance_2 {
  backendset_name  = oci_load_balancer_backend_set.BS-DEVOPS-CHALLENGE.name
  backup           = "false"
  drain            = "false"
  ip_address       = var.private_ip_2
  load_balancer_id = oci_load_balancer_load_balancer.LB-DEVOPS-CHALLENGE.id
  offline = "false"
  port    = "5000"
  weight  = "1"
}
```

- Here you create the listener. 

```
resource oci_load_balancer_listener LB-DEVOPS-CHALLENGE_LISTENER-DEVOPS-CHALLENGE {
  connection_configuration {
    backend_tcp_proxy_protocol_options = [
    ]
    backend_tcp_proxy_protocol_version = "0"
    idle_timeout_in_seconds            = "60"
  }
  default_backend_set_name = oci_load_balancer_backend_set.BS-DEVOPS-CHALLENGE.name
  hostname_names = [
  ]
  load_balancer_id = oci_load_balancer_load_balancer.LB-DEVOPS-CHALLENGE.id
  name             = "LISTENER-DEVOPS-CHALLENGE"
  port     = "80"
  protocol = "HTTP"
  rule_set_names = [
  ]
}
```

Finally we can execute the terraform commands:

```
terraform init
terraform plan
terraform apply
```

All the infrastructure has been created.

## Install Node Application with Ansible

Now we have to install the node application. For this let's move to the ansible directory:

```
cd ..
cd ANSIBLE
```

Here we find three files. Let's check them out. The first one is the ```hosts.yaml``` where we specify the public ip of the two instance created before.

```
all:
  hosts:
    <Your_Public_IP_1>:
    <Your_Public_IP_2>:
  vars:
    ansible_ssh_extra_args: '-o StrictHostKeyChecking=no'
```

The second file we install everything we need to make the node application run. Let's check the parts:

- In this section we install node, download the git repository and install the dependencies.

```
- name: Install and Configure node application
  hosts: all
  remote_user: opc
  tasks:
  - name: Install Nodejs
    ansible.builtin.yum:
      name: nodejs
      state: present
    become: true

  - name: Install git
    ansible.builtin.yum:
      name: git
      state: latest
    become: true

  - name: Create directory for cloned repository
    file:
      path: ~/nodeapp
      state: directory

  - name: Clone github repository
    git:
      repo: https://github.com/abkunal/Chat-App-using-Socket.io
      dest: ~/nodeapp
      clone: yes
      update: yes
      accept_hostkey: yes

  - name: Install the npm express
    npm:
      path: ~/nodeapp
      name: express
      state: present

  - name: Install the npm socket.io
    npm:
      path: ~/nodeapp
      name: socket.io
      state: present
```

- We create a service file to make sure the node application is always running and start the application

```
  - name: Create service file
    template:
      src: /path_to_service_file/service
      dest: /etc/systemd/system/nodejs.service
    register: service_conf
    become: true

  - name: Reload systemd daemon
    systemd:
      daemon_reload: yes
    when: service_conf.changed
    become: true

  - name: Start NodeJS service
    service:
      name: nodejs
      state: started
      enabled: yes
    become: true
```

- We open the port 5000 to allow access to the application

```
  - name: Permit traffic in the port of the application
    ansible.posix.firewalld:
      port: 5000/tcp
      permanent: true
      state: enabled
      immediate: true
    become: true
```

The third file will allow us to make sure the node application is always up and running.

```
[Unit]
Description=nodejs-server

[Service]
ExecStart=/usr/bin/node /home/opc/nodeapp/app.js
Restart=on-failure
# Output to syslog
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=nodejs-example
Environment=NODE_ENV=production PORT=5000

[Install]
WantedBy=multi-user.target
```

Finally you install the node application with the ansible command:

```
ansible-playbook -i hosts.yaml playbook.yaml --key-file "/path_to_ssh_key/id_rsa"
```

## Make sure the application is working

You should be able to copy the IP address of the load balancer.
