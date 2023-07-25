resource "ibm_is_vpc_address_prefix" "cpd_vpc_zone_1" {
  name = "${var.vpc}-zone-1"
  
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.cpd_vpc.id
  cidr = "10.231.0.0/26"
}