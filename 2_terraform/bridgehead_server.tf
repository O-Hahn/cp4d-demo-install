variable "bridgehead_name" {}
variable "bridgehead_zone" {}
variable "ssh_key_name" {}
variable "bridgehead_profile" {}
variable "bridgehead_image" {}


data "ibm_is_image" "bridgehead_image" {
    name = "${var.bridgehead_image}"
}

data "ibm_is_ssh_key" "ssh_key_name" {
    name = "${var.ssh_key_name}"
}

resource "ibm_is_subnet_public_gateway_attachment" "public_gateway" {
    subnet         = ibm_is_subnet.cpd_vpc_subnet_zone_1.id
    public_gateway = ibm_is_public_gateway.cpd_vpc_region_1.id
}

resource "ibm_is_instance" "vsi1" {
    name    = var.bridgehead_name
    vpc     = ibm_is_vpc.cpd_vpc.id
    zone    = "${var.region}-1"
    keys    = [data.ibm_is_ssh_key.ssh_key_name.id]
    image   = data.ibm_is_image.bridgehead_image.id

    profile = var.bridgehead_profile
    tags    = var.tags

    primary_network_interface {
        subnet          = ibm_is_subnet.cpd_vpc_subnet_zone_1.id
        security_groups = [ibm_is_vpc.cpd_vpc.default_security_group]
    }

    depends_on = [ibm_container_vpc_cluster.cpd_cluster]
 }

resource "ibm_is_floating_ip" "fip1" {
    name   = "${var.bridgehead_name}-fip1"
    target = ibm_is_instance.vsi1.primary_network_interface[0].id
}

resource "ibm_is_instance_volume_attachment" "data" {
    instance                           = ibm_is_instance.vsi1.id
    name                               = "${var.bridgehead_name}-vol-1"
    profile                            = "general-purpose"
    capacity                           = "2000"
    delete_volume_on_attachment_delete = true
    delete_volume_on_instance_delete   = true
    volume_name                        = "${var.bridgehead_name}-vol-1"
    tags    = var.tags
}