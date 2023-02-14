resource "ibm_is_subnet" "cpd_cluster_subnet_zone_1" {
    name = "${var.cluster_name}-subnet-zone-1"

    vpc  = ibm_is_vpc.cpd_cluster.id
    ipv4_cidr_block = "10.231.0.0/26"
    zone = "${var.region}-1"

    public_gateway = ibm_is_public_gateway.cpd_cluster_region_1.id
    depends_on = [ibm_is_vpc_address_prefix.cpd_cluster_zone_1]
    resource_group = data.ibm_resource_group.target_rg.id
    
  lifecycle {
    create_before_destroy = true
    ignore_changes = [ resource_group ]
   }
}

