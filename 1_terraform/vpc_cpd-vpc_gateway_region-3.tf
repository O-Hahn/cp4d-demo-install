resource "ibm_is_public_gateway" "cpd_vpc_region_3" {
    name = "${var.vpc}-${var.region}-3"
    vpc  = ibm_is_vpc.cpd_vpc.id
    zone = "${var.region}-3"
    resource_group = data.ibm_resource_group.target_rg.id

    lifecycle {
      create_before_destroy = true
      ignore_changes = [ resource_group ]
    }
}
