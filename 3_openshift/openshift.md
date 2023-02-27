# OpenShift Environment customizing

## Login into the environment of ibmcloud and openshift
ibmcloud login --sso
ibmcloud target -g demo
oc login --token=xxx --server=yyy

## Apply global secret on ROKS 

https://cloud.ibm.com/docs/openshift?topic=openshift-registry#cluster_global_pull_secret

oc get secret pull-secret -n openshift-config --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode > dockerconfigjson

echo -n "cp:REPLACE_WITH_GENERATED_ENTITLEMENT_KEY" | base64 -w0
echo -n "cp:"+$IBM_ENTITLEMENT_KEY | base64 -w0

oc get secret/pull-secret -n openshift-config -ojson | \
jq -r '.data[".dockerconfigjson"]' | \
base64 -d - | \
jq '.[]."cp.icr.io" += input' - authority.json > temp_config.json
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=temp_config.json


insert the following lines into the dockerconfigjson - with the IBM Entitlement Key transformed into auth...
"cp.icr.io": {
    "auth": "xxxxxxxxx"
},

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=dockerconfigjson-new.json

## Replace worker nodes from the cluster after changing the global secrets for IBM Registry 
export ROKS_CLUSTER_NAME=cpd

ibmcloud oc worker ls -c $ROKS_CLUSTER_NAME 

ibmcloud oc worker replace -c $ROKS_CLUSTER_NAME -w <workerID_1>


## Install OCS / ODF Storage Foundation 

oc create -f ocs-namespace.yaml
ibmcloud oc cluster addon enable openshift-data-foundation -c $ROKS_CLUSTER_NAME --version 4.10.0 --param "odfDeploy=false"

check if health status is ready:
ibmcloud oc cluster addon get --addon openshift-data-foundation --cluster $ROKS_CLUSTER_NAME

### List the OCS Worker Node Names and export them 
set the ip adresses from the list above onto the env 

ibmcloud oc workers --cluster $ROKS_CLUSTER_NAME --worker-pool $ROKS_CLUSTER_NAME-ocs

export OCS_WORKER1=10.231.0.137
export OCS_WORKER2=10.231.0.72
export OCS_WORKER3=10.231.0.10

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

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=<access_key_id> 
--from-literal=IBM_COS_SECRET_ACCESS_KEY=<secret_access_key>

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=a61b257d82794a568fb75a0425e41a08 --from-literal=IBM_COS_SECRET_ACCESS_KEY=aa64e8ea628cbe7f59bb8ac949fc70cc45a8ff39b300059e

oc get secrets -A | grep cos


### Create the ODF cluster
Edit the cpd-cluster-ocscluster.yaml with the ip-adresses from the ocs-worker 

?? ibmcloud oc cluster addon enable openshift-data-foundation -c $ROKS_CLUSTER_NAME --version 4.10.0 --param "osdSize=1000Gi" --param "workerNodes=${OCS_WORKER1},${OCS_WORKER2},${OCS_WORKER3}"

ibmcloud oc cluster addon ls -c $ROKS_CLUSTER_NAME

oc get pods -A | grep ibm-ocs-operator-controller-manager

oc create -f ocs-cluster.yaml

oc describe ocscluster ocs
