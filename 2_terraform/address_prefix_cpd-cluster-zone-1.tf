resource "ibm_is_vpc_address_prefix" "cpd_cluster_zone_1" {
  name = "${var.cluster_name}-zone-1"
  
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.cpd_cluster.id
  cidr = "10.231.0.0/26"
}