# Create base ROKS Cluster in IBM Cloud
in the terraform folder - edit the tf files to adjust your environment - at least the variables.auto.tfvars file.

## Delete old environment
if needed delete .terraform .terraform.lock.hcl 


## Customize Terraform
cd 2_terraform
cp example.variables.auto.tfvars variables.auto.tfvars
nano variables.auto.tfvars

## Create the cluster in IBM Cloud
terraform init 
terraform apply

## Destroy environment 
terraform destroy