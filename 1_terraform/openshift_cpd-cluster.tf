# Generate assets if OpenShift cluster is managed

resource "ibm_container_vpc_cluster" "cpd_cluster" {
    name = var.cluster_name

    cos_instance_crn = ibm_resource_instance.cpd_cluster_cos.id
    
    kube_version = "4.12_openshift"
    flavor       = "bx2.16x64"
    secondary_storage= "900gb.5iops-tier"
    
    entitlement  = "cloud_pak"
    vpc_id       = ibm_is_vpc.cpd_vpc.id
    
    worker_count = "2"
    resource_group_id = data.ibm_resource_group.target_rg.id
    disable_public_service_endpoint = false

    tags = var.tags
    
    timeouts {
      create = "3h"
      delete = "2h"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_1.id
        name      = "${var.region}-1"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_2.id
        name      = "${var.region}-2"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_3.id
        name      = "${var.region}-3"
    }
}

resource "ibm_container_vpc_worker_pool" "cpd_cluster_ocs" {
    cluster           = var.cluster_name
    
    worker_pool_name  = "${var.cluster_name}-ocs"
    flavor       = "bx2.16x64"
    vpc_id       = ibm_is_vpc.cpd_vpc.id
    worker_count      = "1"
    resource_group_id = data.ibm_resource_group.target_rg.id

    labels = {
        "roks-storage" = "ocs"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_1.id
        name      = "${var.region}-1"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_2.id
        name      = "${var.region}-2"
    }

    zones {
        subnet_id = ibm_is_subnet.cpd_vpc_subnet_zone_3.id
        name      = "${var.region}-3"
    }

    depends_on = [ibm_container_vpc_cluster.cpd_cluster]
}


# Retrieve assets if OpenShift cluster is NOT managed
