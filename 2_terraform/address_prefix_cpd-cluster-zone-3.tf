resource "ibm_is_vpc_address_prefix" "cpd_cluster_zone_3" {
  name = "${var.cluster_name}-zone-3"
  
  zone = "${var.region}-3"
  vpc  = ibm_is_vpc.cpd_cluster.id
  cidr = "10.231.0.128/25"
}