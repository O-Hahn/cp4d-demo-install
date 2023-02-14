# OpenShift Environment customizing

## Apply global secret on ROKS 

https://cloud.ibm.com/docs/openshift?topic=openshift-registry#cluster_global_pull_secret


## Install OCS / ODF Storage Foundation 

oc login --token=xxx --server=yyy

export ROKS_CLUSTER_NAME=cpd
oc create -f /openshift/ocs-namespace.yaml
ibmcloud oc cluster addon enable openshift-data-foundation -c $ROKS_CLUSTER_NAME --version 4.10.0 --param "odfDeploy=false"

check if health status is ready:
ibmcloud oc cluster addon get --addon openshift-data-foundation --cluster $ROKS_CLUSTER_NAME

### List the OCS Worker Node Names and export them 
set the ip adresses from the list above onto the env 

ibmcloud oc workers --cluster $ROKS_CLUSTER_NAME --worker-pool $ROKS_CLUSTER_NAME-ocs

export OCS_WORKER1=10.231.0.71
export OCS_WORKER2=10.231.0.135
export OCS_WORKER3=10.231.0.6

### Label and taint nodes for OFS

oc label node --overwrite $OCS_WORKER1 node-role.kubernetes.io/infra=""
oc label node --overwrite $OCS_WORKER2 node-role.kubernetes.io/infra=""
oc label node --overwrite $OCS_WORKER3 node-role.kubernetes.io/infra=""

oc adm taint nodes $OCS_WORKER1 node.ocs.openshift.io/storage="true":NoSchedule --overwrite
oc adm taint nodes $OCS_WORKER2 node.ocs.openshift.io/storage="true":NoSchedule --overwrite
oc adm taint nodes $OCS_WORKER3 node.ocs.openshift.io/storage="true":NoSchedule --overwrite

?oc label node --overwrite $OCS_WORKER1 cluster.ocs.openshift.io/openshift-storage=
?oc label node --overwrite $OCS_WORKER2 cluster.ocs.openshift.io/openshift-storage=
?oc label node --overwrite $OCS_WORKER3 cluster.ocs.openshift.io/openshift-storage=

oc get nodes

### Create the OCS-Noobar - object storage instance

optional: 
?? ibmcloud resource service-instance-create $ROKS_CLUSTER_NAME-ocs cloud-object-storage standard global

ibmcloud resource service-key-create cos-cred-rw Writer --instance-name $ROKS_CLUSTER_NAME-cos --parameters '{"HMAC": true}'

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=<access_key_id> --from-literal=IBM_COS_SECRET_ACCESS_KEY=<secret_access_key>

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=51a6df7fc9e14d00ae757ea486f2d522 --from-literal=IBM_COS_SECRET_ACCESS_KEY=9ba62d9aace533c36d6a1e52ab4f4e284654a81841448e2b

oc get secrets -A | grep cos


### Create the ODF cluster
Edit the cpd-cluster-ocscluster.yaml with the ip-adresses from the ocs-worker 

?? ibmcloud oc cluster addon enable openshift-data-foundation -c $ROKS_CLUSTER_NAME --version 4.10.0 --param "osdSize=1000Gi" --param "workerNodes=${OCS_WORKER1},${OCS_WORKER2},${OCS_WORKER3}"

ibmcloud oc cluster addon ls -c $ROKS_CLUSTER_NAME

oc get pods -A | grep ibm-ocs-operator-controller-manager

oc create -f openshift/ocs-cluster.yaml

oc describe ocscluster ocs
