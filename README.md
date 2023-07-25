# Install a new CP4D ROKS Cluster environment

This Repo is the documentation how to setup an own IBM OpenShift Cluster in the IBM Cloud with additional packages. 

## Infos

With terraform a new VPC is created with a bridgehead server and an OCP Cluster - sized for minimal production use. 
The Bridgehead Server is the installer environment for CP4D and its components.
OpenShift needs to be customized for ODF and the pull of IBM Repo Assets.
The installation of CP4D is done within the bridgehead server environment.

## Steps

* [Create IBM Cluster with Terraform](./1_terraform/terraform.md)

* [Install VM for CP4D-Install](./2_installer_env/installer.md)

* [OpenShift Customizing](./3_openshift/openshift.md)

* [Install the CP4D](./4_cpd-install/cpd-install.md)

