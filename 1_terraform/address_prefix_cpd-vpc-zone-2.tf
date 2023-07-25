resource "ibm_is_vpc_address_prefix" "cpd_vpc_zone_2" {
  name = "${var.vpc}-zone-2"
  
  zone = "${var.region}-2"
  vpc  = ibm_is_vpc.cpd_vpc.id
  cidr = "10.231.0.64/26"
}