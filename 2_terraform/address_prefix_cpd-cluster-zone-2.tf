resource "ibm_is_vpc_address_prefix" "cpd_cluster_zone_2" {
  name = "${var.cluster_name}-zone-2"
  
  zone = "${var.region}-2"
  vpc  = ibm_is_vpc.cpd_cluster.id
  cidr = "10.231.0.64/26"
}