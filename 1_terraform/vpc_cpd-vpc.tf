
resource "ibm_is_vpc" "cpd_vpc" {
    name = var.vpc
    resource_group = data.ibm_resource_group.target_rg.id

    address_prefix_management = "manual"
    default_network_acl_name = "${var.vpc}-acl-default"
    default_security_group_name = "${var.vpc}-sg-default"
    default_routing_table_name = "${var.vpc}-rt-default"

    tags = var.tags

    lifecycle {
        create_before_destroy = true
        ignore_changes = [ resource_group ]
    }
    
}


# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
    group     = ibm_is_vpc.cpd_vpc.default_security_group
    direction = "inbound"
    remote    = "0.0.0.0/0"

    tcp {
      port_min = 22
      port_max = 22
    }
}

resource "ibm_is_security_group_rule" "egress_all" {
    group     = ibm_is_vpc.cpd_vpc.default_security_group
    direction = "outbound"
    remote    = "0.0.0.0/0"
}

resource "ibm_is_network_acl" "acl" {
  name = "${var.vpc}-acl"
  vpc  = ibm_is_vpc.cpd_vpc.id

  rules {
    name        = "outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }

  rules {
    name        = "inbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
    }
}

# Extra data element so we can always refer to it from other objects

data "ibm_is_vpc" "cpd_vpc" {
    name = var.vpc
    depends_on = [
        ibm_is_vpc.cpd_vpc
    ]
}