
resource "ibm_is_vpc" "cpd_cluster" {
    name = var.cluster_name
    resource_group = data.ibm_resource_group.target_rg.id

    address_prefix_management = "manual"
    default_network_acl_name = "${var.cluster_name}-acl-default"
    default_security_group_name = "${var.cluster_name}-sg-default"
    default_routing_table_name = "${var.cluster_name}-rt-default"

    tags = var.tags

    lifecycle {
        create_before_destroy = true
        ignore_changes = [ resource_group ]
    }
    
}


resource "ibm_is_security_group_rule" "cpd_cluster_ssh" {
    direction = "inbound"
    group = ibm_is_vpc.cpd_cluster.default_security_group
    tcp {
        port_min = 22
        port_max = 22
    }
}

# Extra data element so we can always refer to it from other objects

data "ibm_is_vpc" "cpd_cluster" {
    name = var.cluster_name
    depends_on = [
        ibm_is_vpc.cpd_cluster
    ]
}