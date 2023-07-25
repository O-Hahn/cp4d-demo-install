resource "ibm_is_subnet" "cpd_vpc_subnet_zone_2" {
    name = "${var.vpc}-subnet-zone-2"

    vpc  = ibm_is_vpc.cpd_vpc.id 
    ipv4_cidr_block = "10.231.0.64/26"
    zone = "${var.region}-2"
    
    public_gateway = ibm_is_public_gateway.cpd_vpc_region_2.id
    depends_on = [ibm_is_vpc_address_prefix.cpd_vpc_zone_2]
    resource_group = data.ibm_resource_group.target_rg.id

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ resource_group ]
   }
}

