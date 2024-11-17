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

#VCN
resource "oci_core_vcn" "vcn_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "VCN-DEVOPS-CHALLENGE"
    cidr_blocks = ["10.0.0.0/16"]
}

#Public Subnet in AD 1
resource "oci_core_subnet" "subnet_1_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "PUBLIC-SUBNET-1-DEVOPS-CHALLENGE"
    vcn_id = oci_core_vcn.vcn_devops_challenge.id
    availability_domain = "fGuh:PHX-AD-1"
    cidr_block = "10.0.0.0/24"
}

#Public Subnet in AD 2

resource "oci_core_subnet" "subnet_2_devops_challenge" {
    compartment_id = var.compartment_id
    display_name = "PUBLIC-SUBNET-2-DEVOPS-CHALLENGE"
    vcn_id = oci_core_vcn.vcn_devops_challenge.id
    availability_domain = "fGuh:PHX-AD-2"
    cidr_block = "10.0.1.0/24"
}

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