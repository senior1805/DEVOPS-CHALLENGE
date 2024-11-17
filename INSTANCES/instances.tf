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