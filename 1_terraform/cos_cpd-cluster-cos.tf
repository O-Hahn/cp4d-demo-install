resource "ibm_resource_instance" "cpd_cluster_cos" {
    name     = "${var.cluster_name}-cos"

    plan     = "standard"
    location = "global"
    service  =  "cloud-object-storage"

    tags = var.tags

    resource_group_id = data.ibm_resource_group.target_rg.id
}


