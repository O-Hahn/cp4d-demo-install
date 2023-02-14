#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================

export OCP_URL=https://c114-e.eu-de.containers.cloud.ibm.com:31213
export IMAGE_ARCH=amd64
export OCP_TOKEN=sha256~rDKkGp78p5z9D2GNPYqenIU3UACX21wkNf_fMRH7RGI
export OPENSHIFT_TYPE=self-managed

export STG_CLASS_BLOCK=ocs-storagecluster-ceph-rbd
export STG_CLASS_FILE=ocs-storagecluster-cephfs

export PROJECT_CATSRC=openshift-marketplace
export PROJECT_CPFS_OPS=ibm-common-services        
export PROJECT_CPD_OPS=ibm-common-services
export PROJECT_CPD_INSTANCE=zen-46

export VERSION=4.6.1

export IBM_ENTITLEMENT_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2Njc5ODQzNDksImp0aSI6ImJlN2E3YzlkOGU3YjQ4MTZiYmE5NmY3N2E5ZTUzNGYxIn0._Y3fZkFCn7n1sxpGoRJxJyhqadvXrh6qHLCN3TwCqDQ

export COMPONENTS=cpfs,cpd_platform,wkc,dv,wml,ws

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
