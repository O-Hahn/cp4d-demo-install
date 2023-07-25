# OpenShift Environment customizing

```
export OCP_VPC="your vpc name"
export OCP_TOKEN="your token"
export OCP_URL="your ROKS Cluster Url"
```

## Login into the cpd environment on ibmcloud and openshift (ROKS)

```
ibmcloud login --sso
ibmcloud target -g demo

oc login --token=$OCP_TOKEN --server=$OCP_URL
```

## Get IBM entitlement.key

https://myibm.ibm.com/products-services/containerlibrary

## Apply the Key as global secret on ROKS

See also: https://cloud.ibm.com/docs/openshift?topic=openshift-registry#cluster_global_pull_secret

if running the script - the replacement is done automatically
```
export IBM_ENTITLEMENT_KEY=....yourkey....

./cpd-registry.sh
```

## Replace worker nodes from the cluster after changing the global secrets for IBM Registry 
only needed if script is not called ... 

```
ibmcloud oc worker ls -c $OCP_VPC 
ibmcloud oc worker replace -c $OCP_VPC -w <workerID_1>

for wid in $(ibmcloud oc worker ls -c $OCP_VPC -q | awk '{print $1}');
do 
    echo -e "Replacing Worker $wid\n"
    ibmcloud oc worker replace -c $OCP_VPC -w $wid -f;
    echo -e "\n" 
done
```

## Install OCS / ODF Storage Foundation 
```
oc create -f ocs-namespace.yaml
ibmcloud oc cluster addon enable openshift-data-foundation -c $OCP_VPC --version 4.12.0 --param "odfDeploy=false"

check if health status is ready:
ibmcloud oc cluster addon get --addon openshift-data-foundation --cluster $OCP_VPC
```

### List, Taint and Label OCS Nodes 

```
for ocsw in $(ibmcloud oc workers --cluster $OCP_VPC --worker-pool $OCP_VPC-ocs -q | awk '{print $2}');
do 
    echo -e "Customizing $ocsw\n"
    oc label node --overwrite $ocsw node-role.kubernetes.io/infra=""
    oc adm taint nodes $ocsw node.ocs.openshift.io/storage="true":NoSchedule --overwrite
    echo -e "\n"
done
```

### Create the OCS-Noobar - object storage instance

optional - if noobar objects are seperated: 
```
ibmcloud resource service-instance-create $OCP_VPC-ocs cloud-object-storage standard global
```

```
ibmcloud resource service-key-create cos-cred-rw Writer --instance-name $OCP_VPC-cos --parameters '{"HMAC": true}'

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=<access_key_id> 
--from-literal=IBM_COS_SECRET_ACCESS_KEY=<secret_access_key>

oc -n 'openshift-storage' create secret generic 'ibm-cloud-cos-creds' --type=Opaque --from-literal=IBM_COS_ACCESS_KEY_ID=94f2b9804e94494aad5db25d2f3bb02b --from-literal=IBM_COS_SECRET_ACCESS_KEY=86568361b02092fce3cbfd4febecb5ed27595d48cee1cd37

oc get secrets -A | grep cos

```
### Append Noobar Secrets to the 
```
oc get secrets --namespace=openshift-storage

export NOOBAA_ACCOUNT_CREDENTIALS_SECRET=noobaa-admin
export NOOBAA_ACCOUNT_CERTIFICATE_SECRET=noobaa-s3-serving-cert
```

### Create the ODF cluster
Edit the cpd-cluster-ocscluster.yaml with the ip-adresses from the ocs-worker 

```
echo $(ibmcloud oc workers --cluster $OCP_VPC --worker-pool $OCP_VPC-ocs -q | awk '{print $2}')

?? ibmcloud oc cluster addon enable openshift-data-foundation -c $OCP_VPC --version 4.10.0 --param "osdSize=1000Gi" --param "workerNodes=${OCS_WORKER1},${OCS_WORKER2},${OCS_WORKER3}"

ibmcloud oc cluster addon ls -c $OCP_VPC

oc get pods -A | grep ibm-ocs-operator-controller-manager

oc create -f ocs-cluster.yaml

oc describe ocscluster ocs
```

## QUAY 

```
oc create -f quay-namespace.yaml
```

- Install QUAY from Operator-Hub (RedHat) into quey-enterprise namespace. 
- Create a quay instance by deleting the spec in the quay-yaml and give it a name like "cp4d-registry".
- Wait to become ready 
- Create first User with the gui 
- create a /etc/docker/daemon.json file with 

daemon.json:
{
  "insecure-registries" : ["quay.example.com"]
}

## GitOps

## 


# Additional Temp Infos & Tries

### Apply global secret on ROKS 

```
IBM_EK_B64=$(echo -n "cp:"+$IBM_ENTITLEMENT_KEY | base64 -w0)
TEST2=$(echo '{"cp.icr.io":{"auth":"'$IBM_EK_B64'"}}')
echo $TEST2 | jq '.' 

oc get secret/pull-secret -n openshift-config -ojson | \
jq -r '.data[".dockerconfigjson"]' | \
base64 -d - | \
jq '.[]."cp.icr.io" += input' - authority.json > temp_config.json

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=temp_config.json

oc extract secret/pull-secret -n openshift-config

insert the following lines into the dockerconfigjson - with the IBM Entitlement Key transformed into auth...
"cp.icr.io": {
    "auth": "xxxxxxxxx"
},

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=dockerconfigjson-new.json



echo -n "cp:"+$IBM_ENTITLEMENT_KEY | base64 -w0 

oc get secret pull-secret -n openshift-config --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode > orig_dockerconfigjson

oc registry login --registry="cp.icr.io" --auth-basic="cp:${IBM_ENTITLEMENT_KEY}" --to=./.dockerconfigjson

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./.dockerconfigjson

```

### Label and taint nodes for OFS

```
ibmcloud oc workers --cluster $OCP_VPC --worker-pool $OCP_VPC-ocs

export OCS_WORKER1=10.231.0.132
export OCS_WORKER2=10.231.0.68
export OCS_WORKER3=10.231.0.10

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
```