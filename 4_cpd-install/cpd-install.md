# Install CP4D

## Prepare the environment
Edit the cpd-demo-env.sh file with your credentials and informations. 

nano /cpd-demo-env/cpd-demo-env.sh
source /cpd-demo-env/cpd-demo-env.sh

oc new-project ${PROJECT_CPFS_OPS}
oc new-project ${PROJECT_CPD_INSTANCE}

## Install CP4D Common Services

cpd-cli manage login-to-ocp \
--server=${OCP_URL} \
--token=${OCP_TOKEN}

cpd-cli manage oc get nodes

cpd-cli manage apply-scc \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--components=wkc

?? cpd-cli manage apply-crio --openshift-type=${OPENSHIFT_TYPE}
?? cpd-cli manage apply-db2-kubelet --openshift-type=${OPENSHIFT_TYPE}

cpd-cli manage add-icr-cred-to-global-pull-secret ${IBM_ENTITLEMENT_KEY}

cpd-cli manage apply-olm \
--release=${VERSION} \
--components=${COMPONENTS} \
--cs_ns=${PROJECT_CPFS_OPS} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--preview=false

cpd-cli manage get-olm-artifacts \
--subscription_ns=${PROJECT_CPFS_OPS}

## Install the CP4D Instance with needec components

cpd-cli manage setup-instance-ns \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--cs_ns=${PROJECT_CPFS_OPS}

cpd-cli manage apply-cr \
--components=${COMPONENTS} \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--cs_ns=${PROJECT_CPFS_OPS} \
--license_acceptance=true

## check the status with:
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE}

## get the admin user password after everything has been installed:
cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--get_admin_initial_credentials=true

oc get Ibmcpd ibmcpd-cr -n ${PROJECT_CPD_INSTANCE} -o jsonpath="{.spec.zenVaultEnabled}{'\n'}"
oc get Ibmcpd ibmcpd-cr -n ${PROJECT_CPD_INSTANCE} -o jsonpath="{.status.controlPlaneStatus}{'\n'}"


## Additional Informations 

### Uninstall

oc project ${PROJECT_CPD_INSTANCE}

cpd-cli manage login-to-ocp \
--username=${OCP_USERNAME} \
--password=${OCP_PASSWORD} \
--server=${OCP_URL}

cpd-cli manage setup-tethered-ns \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--tethered_instance_ns=${PROJECT_TETHERED} \
--remove=true

cpd-cli manage delete-cr \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--components=${COMPONENTS}

export RESOURCE_LIST=configmaps,persistentvolumeclaims,pods,secret,serviceaccounts,Service,statefulsets,deployment,job,cronjob,ReplicaSet,Route,RoleBinding,Role,PodDisruptionBudget,OperandRequest
oc get ${RESOURCE_LIST} -n ${PROJECT_CPD_INSTANCE} --ignore-not-found
oc delete <object-type> <object-name>

oc delete project $PROJECT_CPD_INSTANCE

cpd-cli manage delete-olm-artifacts

### Cloudwerkstatt working session docu

cpd-cli manage oc get nodes

cpd-cli manage apply-scc \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--components=wkc

cpd-cli manage apply-crio --openshift-type=${OPENSHIFT_TYPE}
cpd-cli manage apply-db2-kubelet --openshift-type=${OPENSHIFT_TYPE}

cpd-cli manage apply-olm \
--release=${VERSION} \
--components=${COMPONENTS} \
--cs_ns=${PROJECT_CPFS_OPS} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--preview=false

cpd-cli manage get-olm-artifacts \
--subscription_ns=${PROJECT_CPFS_OPS}

cpd-cli manage setup-instance-ns \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--cs_ns=${PROJECT_CPFS_OPS}

Now install and deploy the Cloud Pak services: which will take the longes time. we should go for the screen utility
cpd-cli manage apply-cr \
--components=${COMPONENTS} \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--cs_ns=${PROJECT_CPFS_OPS} \
--license_acceptance=true

check the status with:
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE}

get the admin user password after everything has been installed:
cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--get_admin_initial_credentials=true

oc get Ibmcpd ibmcpd-cr -n ${PROJECT_CPD_INSTANCE} -o jsonpath="{.spec.zenVaultEnabled}{'\n'}"
oc get Ibmcpd ibmcpd-cr -n ${PROJECT_CPD_INSTANCE} -o jsonpath="{.status.controlPlaneStatus}{'\n'}"
