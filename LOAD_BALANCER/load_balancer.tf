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