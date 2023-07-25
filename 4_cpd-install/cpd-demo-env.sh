#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================

export OCP_VPC=cpd
export OCP_URL=https://c113-e.eu-de.containers.cloud.ibm.com:31369
export IMAGE_ARCH=amd64
export OCP_TOKEN=sha256~2zbE_Rl0HaqzXOYnbwRtcsU75rAkHNQvNSbj_a9hma4 
export OPENSHIFT_TYPE=roks

export CPD_CLI_MANAGE_WORKSPACE=/home/developer/Git/cp4d-demo-install

export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
export STG_CLASS_FILE=ocs-storagecluster-cephfs

export PROJECT_CATSRC=openshift-marketplace
export PROJECT_CPFS_OPS=ibm-common-services        
export PROJECT_CPD_OPS=ibm-common-services
export PROJECT_CPD_INSTANCE=zen-47

export PROJECT_CERT_MANAGER=ibm-cert-manager
export PROJECT_LICENSE_SERVICE=ibm-licensing
export PROJECT_SCHEDULING_SERVICE=cpd-scheduler
export PROJECT_CPD_INST_OPERATORS=ibm-common-services
export PROJECT_CPD_INST_OPERANDS=zen-47

export NOOBAA_ACCOUNT_CREDENTIALS_SECRET=noobaa-admin
export NOOBAA_ACCOUNT_CERTIFICATE_SECRET=noobaa-s3-serving-cert

# export PRIVATE_REGISTRY_LOCATION=local-reg-quay-quay.cp4d-443210-0e5faca49082f37aff4ae4e3f0d1a4a7-0000.eu-de.containers.appdomain.cloud
# export PRIVATE_REGISTRY_PUSH_USER=cp4d
# export PRIVATE_REGISTRY_PUSH_PASSWORD=Cp4D2Ibm#

export VERSION=4.7.0

export IBM_ENTITLEMENT_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2Njc5ODQzNDksImp0aSI6ImJlN2E3YzlkOGU3YjQ4MTZiYmE5NmY3N2E5ZTUzNGYxIn0._Y3fZkFCn7n1sxpGoRJxJyhqadvXrh6qHLCN3TwCqDQ

export COMPONENTS=ibm-cert-manager,ibm-licensing,cpfs,cpd_platform,wkc,dv,wml,ws,

# ------------------------------------------------------------------------------
# Additional and other customizing
# ------------------------------------------------------------------------------

# export CPD_CLI_MANAGE_WORKSPACE=<enter a fully qualified directory>
# export OLM_UTILS_LAUNCH_ARGS=<enter launch arguments>

# export OPENSHIFT_TYPE=roks
# export OCP_USERNAME=<enter your username>
# export OCP_PASSWORD=<enter your password>

# export PROJECT_TETHERED=<enter the tethered project>

# export PRIVATE_REGISTRY_LOCATION=<enter the location of your private container registry>
# export PRIVATE_REGISTRY_PUSH_USER=<enter the username of a user that can push to the registry>
# export PRIVATE_REGISTRY_PUSH_PASSWORD=<enter the password of the user that can push to the registry>
# export PRIVATE_REGISTRY_PULL_USER=<enter the username of a user that can pull from the registry>
# export PRIVATE_REGISTRY_PULL_PASSWORD=<enter the password of the user that can pull from the registry>

# export COMPONENTS=cpfs,scheduler,cpd_platform,<component-ID>
