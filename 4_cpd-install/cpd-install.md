# Install CP4D 4.7
https://www.ibm.com/docs/en/cloud-paks/cp-data/4.7.x?topic=installing

## select right directory for all logs
cd ~/Git/cp4d-demo-install

## Prepare the CPD environment
Edit the cpd-demo-env.sh file with your credentials and informations. 

``` 
nano /cpd-demo-env/cpd-demo-env.sh
source /cpd-demo-env/cpd-demo-env.sh
source ~/.zshrc

cpd-cli manage login-to-ocp \
--server=${OCP_URL} \
--token=${OCP_TOKEN}

cpd-cli manage restart-container

oc new-project ${PROJECT_CPD_INST_OPERATORS}
oc new-project ${PROJECT_CPD_INST_OPERANDS}

oc new-project ${PROJECT_CERT_MANAGER}
oc new-project ${PROJECT_LICENSE_SERVICE}
oc new-project ${PROJECT_SCHEDULING_SERVICE}

``` 

## Install CP4D Base and Common Services

``` 
cpd-cli manage login-to-ocp \
--server=${OCP_URL} \
--token=${OCP_TOKEN}

oc project ${PROJECT_CPD_INSTANCE}

cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_LICENSE_SERVICE}

cpd-cli manage apply-scheduler \
--release=${VERSION} \
--license_acceptance=true \
--scheduler_ns=${PROJECT_SCHEDULING_SERVICE}

cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}


cpd-cli manage setup-mcg \
--components=watson_assistant \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--noobaa_account_secret=${NOOBAA_ACCOUNT_CREDENTIALS_SECRET} \
--noobaa_cert_secret=${NOOBAA_ACCOUNT_CERTIFICATE_SECRET}

cpd-cli manage setup-mcg \
--components=watson_discovery \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--noobaa_account_secret=${NOOBAA_ACCOUNT_CREDENTIALS_SECRET} \
--noobaa_cert_secret=${NOOBAA_ACCOUNT_CERTIFICATE_SECRET}

cpd-cli manage setup-mcg \
--components=watson_ks \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--noobaa_account_secret=${NOOBAA_ACCOUNT_CREDENTIALS_SECRET} \
--noobaa_cert_secret=${NOOBAA_ACCOUNT_CERTIFICATE_SECRET}


cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true

oc apply -f - <<EOF
apiVersion: v1
data:
  DB2U_RUN_WITH_LIMITED_PRIVS: "false"
kind: ConfigMap
metadata:
  name: db2u-product-cm
  namespace: ${PROJECT_CPD_INST_OPERATORS}
EOF

cp 4_cpd-install/install-options.yml ${CPD_CLI_MANAGE_WORKSPACE}/work/. 

cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=${COMPONENTS}

?? cpd-cli manage apply-db2-kubelet

``` 

### Install the CP4D with its services

``` 

cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=cpd_platform \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=${COMPONENTS} \
--param-file=/tmp/work/install-options.yml \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

cpd-cli manage apply-cr \
--components=wkc \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--param-file=/tmp/work/install-options.yml \
--license_acceptance=true


cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}

cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--get_admin_initial_credentials=true

``` 

### If air-gap with quay

``` 
cpd-cli manage login-private-registry \
${PRIVATE_REGISTRY_LOCATION} \
${PRIVATE_REGISTRY_PUSH_USER} \
${PRIVATE_REGISTRY_PUSH_PASSWORD}

cpd-cli manage list-images \
--components=${COMPONENTS} \
--release=${VERSION} \
--inspect_source_registry=true

grep "level=fatal" list_images.csv

sed -e '/gpu/d' ./cpd-cli-workspace/olm-utils-workspace/work/offline/${VERSION}/ibm-wsl-runtimes-*-images.csv

sed -e /nlp/d' ./cpd-cli-workspace/olm-utils-workspace/work/offline/${VERSION}/ibm-wsl-runtimes-*-images.csv


cpd-cli manage apply-icsp \
--registry=${PRIVATE_REGISTRY_LOCATION}

``` 

### install WKC before 4.7

https://www.ibm.com/docs/en/cloud-paks/cp-data/4.6.x?topic=installing

``` 
cpd-cli manage oc get nodes

#cpd-cli manage apply-scc \
#--cpd_instance_ns=${PROJECT_CPD_INSTANCE} \
#--components=wkc
``` 

following steps are not needed on IBM Cloud VPC-2
``` 
?? cpd-cli manage apply-crio --openshift-type=${OPENSHIFT_TYPE}
?? cpd-cli manage apply-db2-kubelet --openshift-type=${OPENSHIFT_TYPE}

following step is redundant to the openshift task for global registry cred. If Worker nodes are replaced - skip
?? cpd-cli manage add-icr-cred-to-global-pull-secret ${IBM_ENTITLEMENT_KEY}
``` 

### Install the foundational services
``` 

cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true

``` 


### Customize Environment for WKC
for WKC Install you need a special config during install for DB2 - therefore copy install-opitons file into the cpd-cli-workspace folder

``` 
oc apply -f - <<EOF
apiVersion: v1
data:
  DB2U_RUN_WITH_LIMITED_PRIVS: "false"
kind: ConfigMap
metadata:
  name: db2u-product-cm
  namespace: ${PROJECT_CPD_INST_OPERATORS}
EOF
``` 

### Old version needed 4.6.x

``` 
cp 4_cpd-install/install-options.yml cpd-cli-workspace/olm-utils-workspace/work/.

cpd-cli manage apply-db2-kubelet
``` 

To add for DB2 special tuning parameters (-m 50 means limit to 50GiB)
``` 
./cpd-crt-tune.sh -m 50 -c
``` 

### Install the common services 4.7.x and CP4D with its components
``` 

cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true

cpd-cli manage get-license \
--release=${VERSION} \
--license-type=EE

cpd-cli manage apply-olm \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=${COMPONENTS}

cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=${COMPONENTS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true

cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}

``` 

### Install the common services 4.6.x

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
