variable "ibmcloud_api_key" {}
variable "vpc" {}
variable "region" {}
variable "resource_group" {}
variable "cluster_name" {}
variable "tags" {}

terraform {
  required_version = ">= 0.13"
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
  }
}