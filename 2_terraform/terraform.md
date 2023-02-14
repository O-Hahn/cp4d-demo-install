# Create base ROKS Cluster in IBM Cloud
in the terraform folder - edit the scripts to adjust your environment - at least the variables.auto.tfvars file.

## Customize Terraform
cd 1_terraform
cp example.variables.auto.tfvars variables.auto.tfvars
nano variables.auto.tfvars

## Create the cluster in IBM Cloud
terraform init 
terraform apply
