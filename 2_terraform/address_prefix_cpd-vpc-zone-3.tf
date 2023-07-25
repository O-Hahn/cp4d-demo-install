resource "ibm_is_vpc_address_prefix" "cpd_vpc_zone_3" {
  name = "${var.vpc}-zone-3"
  
  zone = "${var.region}-3"
  vpc  = ibm_is_vpc.cpd_vpc.id
  cidr = "10.231.0.128/25"
}