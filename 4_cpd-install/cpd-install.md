# Install CP4D

https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=installing

## Prepare the CPD environment
Edit the cpd-demo-env.sh file with your credentials and informations. 

``` 
cpd-cli manage login-to-ocp \
--server=${OCP_URL} \
--token=${OCP_TOKEN}

nano /cpd-demo-env/cpd-demo-env.sh
source /cpd-demo-env/cpd-demo-env.sh
source ~/.zshrc

oc new-project ${PROJECT_CPFS_OPS}
oc new-project ${PROJECT_CPD_INSTANCE}
``` 

## Install CP4D Common Services

``` 
cpd-cli manage login-to-ocp \
--server=${OCP_URL} \
--token=${OCP_TOKEN}

oc project ${PROJECT_CPD_INSTANCE}

cpd-cli manage oc get nodes

cpd-cli manage apply-scc \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--components=wkc
``` 

following steps are not needed on IBM Cloud VPC-2
``` 
?? cpd-cli manage apply-crio --openshift-type=${OPENSHIFT_TYPE}
?? cpd-cli manage apply-db2-kubelet --openshift-type=${OPENSHIFT_TYPE}

following step is redundant to the openshift task for global registry cred. If Worker nodes are replaced - skip
?? cpd-cli manage add-icr-cred-to-global-pull-secret ${IBM_ENTITLEMENT_KEY}
``` 

### Customize Environment for WKC
for WKC Install you need a special config during install for DB2 - therefore copy install-opitons file into the cpd-cli-workspace folder

``` 
cp 4_cpd-install/install-options.yml cpd-cli-workspace/olm-utils-workspace/work/.

cpd-cli manage apply-db2-kubelet
``` 

To add for DB2 special tuning parameters (-m 50 means limit to 50GiB)
``` 
./cpd-crt-tune.sh -m 50 -c
``` 

### Install the common services
``` 
cpd-cli manage apply-olm \
--release=${VERSION} \
--components=${COMPONENTS} \
--cs_ns=${PROJECT_CPFS_OPS} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--preview=false
``` 

``` 
cpd-cli manage get-olm-artifacts \
--subscription_ns=${PROJECT_CPFS_OPS}
``` 

## Install the CP4D Instance with needec components
``` 
cpd-cli manage setup-instance-ns \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--cpd_operator_ns=${PROJECT_CPD_OPS} \
--cs_ns=${PROJECT_CPFS_OPS}
``` 

``` 
- Kernel Parameter Settings anpassen 

cpd-cli manage apply-db2-kubelet
``` 

``` 
cpd-cli manage apply-cr \
--components=${COMPONENTS} \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--cs_ns=${PROJECT_CPFS_OPS} \
--license_acceptance=true \
--param-file=/tmp/work/install-options.yml
``` 

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



# delete instance

### Uninstall
```
oc project ${PROJECT_CPD_INSTANCE}

cpd-cli manage setup-tethered-ns \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--tethered_instance_ns=${PROJECT_TETHERED} \
--remove=true

cpd-cli manage delete-cr \
--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
--components=${COMPONENTS}

export RESOURCE_LIST=configmaps,persistentvolumeclaims,pods,secret,serviceaccounts,Service,StatefulSets,deployment,job,cronjob,ReplicaSet,Route,RoleBinding,Role,PodDisruptionBudget,OperandRequest

for res in $(oc get ${RESOURCE_LIST} -n ${PROJECT_CPD_INSTANCE} --ignore-not-found | awk '{print $1}');
do
    echo -e "ressource $res will be deleted \n "
    oc delete ${res}
done

oc delete project $PROJECT_CPD_INSTANCE

cpd-cli manage delete-olm-artifacts

```
