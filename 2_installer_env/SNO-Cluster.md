# Installing CP4D 4.7.0 with WKC service on a TechZone Single Node OpenShift 4.12 cluster using the master single node 64x256 flavor

current info: 
https://github.ibm.com/claus-huempel/cpd-sno
https://github.ibm.com/claus-huempel/cpd-sno/blob/main/techzone/index.md


# 1. Provisioning a TechZone OCP SNO cluster
- Go to https://techzone.ibm.com/my/reservations/create/6495f9f85c870e00179901fa
- Click **Reserve now**
- Select **Purpose** -> **Practice / Self-Eduction**
- Click the **checkbox** to confirm that no customer data is being used
- Leave the **opportunity number empty**
- Enter a description for the Purpose
- Choose the **geography** **DAL12** (other geographies are WDC04, LON02, LON06, FRA04 and TOK02)
- Leave the defaults for "End date time", "OCP/Kubernetes Cluster Network" and "Enable FIPS Security"
  - Note: it is very important to leave the default **Enable FIPS Security = NO**, as some watsonx.date services do currently not run using FIPS.
- Choose the **master single node flavor**. Choose the **64x256** flavor
- Choose the **OpenShift version 4.12**
- Leave the defaults for "OCP/Kubernetes Service Network"
- Eventually add notes
- Click **Submit**

This will kick-off the provisioning process of your OCP SNO cluster in TechZone. You will receive an email, that the provisoning has started. And after approx. 1 hour you will receive another email incicating that your environment is ready.

![image](https://media.github.ibm.com/user/57704/files/1d41a2a0-dd04-4c57-b501-40cb5dacad50)


# 2. Preparing the bastion host
In this step, you will prepare the bastion host that come with the SNO host, to serve as NFS server to host the NFS storage for the OCP SNO cluster, and you will setup the bastion as a client workstation for Cloud Pak for Data to be able to install CPD on the OCP SNO.

### Step 2.1 - Login to the bastion host via ssh.

### Step 2.2 - Switch to root user
```
sudo su -
```

### Step 2.3 - Setup NFS server
You will install the NFS server package on the bastion and configure the /export directory as NFS share for later use by CPD as shared storage.
```
yum -y install nfs-utils
systemctl enable --now nfs-server rpcbind
systemctl start nfs-server
mkdir /export
touch /etc/exports
echo "/export *(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
firewall-cmd --add-service=nfs --permanent
firewall-cmd --add-service={nfs3,mountd,rpc-bind} --permanent
firewall-cmd --reload
systemctl restart nfs-server
systemctl status nfs-server
```

### Step 2.4 - Install the screen utility
```
yum -y install screen
```

### Step 2.5.1 - Download and install the CPD 4.7.0 cpd-cli utility
```
wget https://github.com/IBM/cpd-cli/releases/download/v13.0.0/cpd-cli-linux-EE-13.0.0.tgz
tar -xzvf cpd-cli-linux-EE-13.0.0.tgz
mv cpd-cli-linux-EE-13.0.0-9/* .
rm -rf cpd-cli-linux-EE-13.0.0-9
rm -f cpd-cli-linux-EE-13.0.0.tgz
./cpd-cli version
```

### Step 2.5.2 - Download and install the CPD 4.7.1 cpd-cli utility
```
wget https://github.com/IBM/cpd-cli/releases/download/v13.0.1/cpd-cli-linux-EE-13.0.1.tgz
tar -xzvf cpd-cli-linux-EE-13.0.1.tgz
mv cpd-cli-linux-EE-13.0.1-26/* .
rm -rf cpd-cli-linux-EE-13.0.1-26
rm -f cpd-cli-linux-EE-13.0.1.tgz
./cpd-cli version
```

### Step 2.6 - Define environment variables
- the API URL
- the kubeadmin password
- your [IBM entitlement API key for Cloud Pak for Data](https://www.ibm.com/docs/en/cloud-paks/cp-data/4.7.x?topic=information-obtaining-your-entitlement-api-key) 
```
export SNO_API_URL=<replace with the value of API URL from the TechZone READY email>
export SNO_CLUSTER_ADMIN_PWD=<replace with the value of Console Admin Password from the TechZone READY email>
export SNO_IBM_ENTITLEMENT_KEY=<replace with the value of your IBM Entitlement API key>
```

An example for these environment variables would look like this:
```
export SNO_API_URL=https://api.ocp-310000kjjw-ikg3.cloud.techzone.ibm.com:6443
export SNO_CLUSTER_ADMIN_PWD=aYqWK-cLqBs-9FGkF-eqbN9
export SNO_IBM_ENTITLEMENT_KEY=eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cxxxxxxxxx
```

### Step 2.7 - Add an additional entry for the API host to the /etc/hosts file.
This is needed so that the cpd-cli commands, that run in a container, can contact the OCP SNO cluster on the TechZone infrastruture.
```
export SNO_API_HOST=$(echo $SNO_API_URL | sed 's/https:\/\///g' | sed 's/:6443//g')
echo "192.168.252.1 $SNO_API_HOST" >> /etc/hosts
```

### Step 2.8 - Validate that you can login as Kubeadmin user to your OCP SNO cluster
You should see a "Login successful" message.
```
oc login -u kubeadmin -p $SNO_CLUSTER_ADMIN_PWD $SNO_API_URL --insecure-skip-tls-verify
```

### Step 2.9 - Create the cpd_vars.sh file
```
tee cpd_vars.sh <<EOF
#===============================================================================
# Cloud Pak for Data installation variables
#===============================================================================

# ------------------------------------------------------------------------------
# Cluster
# ------------------------------------------------------------------------------
export OCP_URL="$SNO_API_HOST:6443"
export OPENSHIFT_TYPE="self-managed"
export IMAGE_ARCH="x86_64"
export OCP_USERNAME="kubeadmin"
export OCP_PASSWORD="$SNO_CLUSTER_ADMIN_PWD"
export OCP_TOKEN="$(oc whoami -t)"

# ------------------------------------------------------------------------------
# Projects
# ------------------------------------------------------------------------------
export PROJECT_CERT_MANAGER="ibm-cert-manager"
export PROJECT_LICENSE_SERVICE="ibm-licensing"
export PROJECT_SCHEDULING_SERVICE="cpd-scheduler"
export PROJECT_CPD_INST_OPERATORS="cpd-operators"
export PROJECT_CPD_INST_OPERANDS="zen"

# ------------------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------------------
export STG_CLASS_BLOCK=nfs-storage-provisioner
export STG_CLASS_FILE=nfs-storage-provisioner

# ------------------------------------------------------------------------------
# IBM Entitled Registry
# ------------------------------------------------------------------------------
export IBM_ENTITLEMENT_KEY=$SNO_IBM_ENTITLEMENT_KEY

# ------------------------------------------------------------------------------
# Cloud Pak for Data version
# ------------------------------------------------------------------------------
export VERSION=4.7.0

# ------------------------------------------------------------------------------
# NFS Storage
# ------------------------------------------------------------------------------
export NFS_SERVER_LOCATION=192.168.252.2
export NFS_PATH=/export
export PROJECT_NFS_PROVISIONER=nfs-provisioner
export NFS_STORAGE_CLASS=nfs-storage-provisioner
export NFS_IMAGE=k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2

# ------------------------------------------------------------------------------
# Components
# ------------------------------------------------------------------------------
export COMPONENTS=cpfs,cpd_platform,wkc
EOF
```


# 3. Preparing the OCP SNO cluster
### Step 3.1 - Change the Kubelet config
In the Kubelet config, change CRI-O settings, increase maximal numbers of the pods and enable unsafe systctls for Db2 services.
```
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: cp4d-sno-config
spec:
  machineConfigPoolSelector:
    matchLabels:
      pools.operator.machineconfiguration.openshift.io/master: ""
  kubeletConfig:
    podPidsLimit: 12288
    allowedUnsafeSysctls:
      - "kernel.msg*"
      - "kernel.shm*"
      - "kernel.sem"
    podsPerCore: 0
    maxPods: 500
EOF
```

Your OCP SNO cluster will be rebooted to apply the changes. Verify that the changes have been applied.
```
watch -n 10 oc get mcp
```

Wait until the output of the command shows similar output to this. This could take up to 10 minutes.
```
Every 10.0s: oc get mcp                                                                                                            bastion-gym-lan: Sun Jul  9 09:29:19 2023

NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT
AGE
master   rendered-master-1da8f15c38bedc46b2637af611cc38a7   True      False      False      1              1                   1                     0
164m
worker   rendered-worker-2d723a65df313e722c3b0b37f6ca8814   True      False      False      0              0                   0                     0
164m
```

### Step 3.2 - Source the CPD CLI environment variables from the cpd_vars.sh file.
```
source cpd_vars.sh
```

### Step 3.3 - Run the cpd-cli manage login command.
Note, that when running the command for the first time this will take some time to complete, as the olm-utils container image will be downloaded from the Internet.
```
./cpd-cli manage login-to-ocp --token=${OCP_TOKEN} --server=${OCP_URL}
```

Successful completion of the login command would look like the following.
```
Using project "default" on server "https://api.ocp-310000kjjw-ikg3.cloud.techzone.ibm.com:6443".
[SUCCESS] 2023-07-09T09:39:14.440627Z You may find output and logs in the /root/cpd-cli-workspace/olm-utils-workspace/work directory.
[SUCCESS] 2023-07-09T09:39:14.440660Z The login-to-ocp command ran successfully.
```

### Step 3.4 - Run the cpd-cli manage setup-nfs-provisioner command to setup the NFS provisioner and create a storage class on your OCP SNO cluster.
```
./cpd-cli manage setup-nfs-provisioner \
--nfs_server=${NFS_SERVER_LOCATION} \
--nfs_path=${NFS_PATH} \
--nfs_provisioner_ns=${PROJECT_NFS_PROVISIONER} \
--nfs_storageclass_name=${NFS_STORAGE_CLASS} \
--nfs_provisioner_image=${NFS_IMAGE}
```

Successful completion of the setup-nfs-provisioner command should look like this:
```
[SUCCESS] 2023-07-09T09:44:19.563535Z You may find output and logs in the /root/cpd-cli-workspace/olm-utils-workspace/work directory.
[SUCCESS] 2023-07-09T09:44:19.563567Z The setup-nfs-provisioner command ran successfully.
```

Verify that the NFS storage class has been created.
```
oc get sc
```

Output:
```
NAME                      PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-storage-provisioner   k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate           false                  2m
```

Create a test PVC  using the newly created storage class.
```
cat <<EOF | oc apply -f - 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-claim
spec:
  storageClassName: nfs-storage-provisioner
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF
```

Verify that the PVC has been created and has been bound.
```
oc get pvc
```

Output:
```
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS              AGE
test-claim   Bound    pvc-22d89697-4fa2-461a-b705-3cb47544c9e2   1Gi        RWX            nfs-storage-provisioner   11s
```

You can know go the next section to setup CPD 4.7.0 and services on your OCP SNO cluster.


# 4. Installing CP4D 4.7.0 platform and services

### Step 4.1 - Open a screen session.
This will allow your to reconnect to your terminal via screen -r if ever you loose the SSH connection to the bastion.
```
screen
```

### Step 4.2 - Create new projects for CPD the installation.
```
oc new-project ${PROJECT_CERT_MANAGER}
oc new-project ${PROJECT_LICENSE_SERVICE}
oc new-project ${PROJECT_SCHEDULING_SERVICE}
oc new-project ${PROJECT_CPD_INST_OPERATORS}
oc new-project ${PROJECT_CPD_INST_OPERANDS}
```

### Step 4.3 - Add your entitlement key to the global pull secret.
```
./cpd-cli manage add-icr-cred-to-global-pull-secret --entitled_registry_key=${IBM_ENTITLEMENT_KEY}
```

Output:
```
[SUCCESS] 2023-07-09T10:07:45.755894Z The add-icr-cred-to-global-pull-secret command ran successfully.
```

### Step 4.4 - Install the shared cluster components
This will install the cert manager and licensing services.
```
./cpd-cli manage apply-cluster-components \
--release=${VERSION} \
--license_acceptance=true \
--cert_manager_ns=${PROJECT_CERT_MANAGER} \
--licensing_ns=${PROJECT_LICENSE_SERVICE}
```

Output:
```
[SUCCESS] 2023-07-09T10:15:16.847729Z The apply-cluster-components command ran successfully.
```

Verify that all the pods in ibm-licensing and ibm-cert-manager are running.
```
oc get pods -n ${PROJECT_LICENSE_SERVICE}; oc get pods -n ${PROJECT_CERT_MANAGER}
```

Output:
```
NAME                                                              READY   STATUS      RESTARTS   AGE
b9109a1525329fd9b6418a61e823cfb8d573e1d73ca82823236babfceflcmzm   0/1     Completed   0          7m11s
cert-manager-cainjector-5dcd976f6d-xm8d7                          1/1     Running     0          6m28s
cert-manager-controller-5c875b7cd8-8bpx8                          1/1     Running     0          6m28s
cert-manager-webhook-6ffd9d67f4-8j6bm                             1/1     Running     0          6m27s
ibm-cert-manager-catalog-sk6vq                                    1/1     Running     0          9m30s
ibm-cert-manager-operator-f9c4495dc-vr8kc                         1/1     Running     0          6m48s
NAME                                                              READY   STATUS      RESTARTS   AGE
5c088c817bf2b8afad19026763236fd2b5ad59beda558d953816429a06cmdv7   0/1     Completed   0          6m21s
ibm-licensing-catalog-skk65                                       1/1     Running     0          8m19s
ibm-licensing-operator-7b77797656-82dsx                           1/1     Running     0          6m6s
ibm-licensing-service-instance-664f49bfb8-b22lj                   1/1     Running     0          2m21s
```

### Step 4.5 - Authorize the instance topology
```
./cpd-cli manage authorize-instance-topology \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

Output:
```
[SUCCESS] 2023-07-09T10:26:30.010901Z The authorize-instance-topology command ran successfully.
```

### Step 4.6 - Setup the instance topology
```
./cpd-cli manage setup-instance-topology \
--release=${VERSION} \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--license_acceptance=true
```

Output:
```
[SUCCESS] 2023-07-09T10:34:31.193194Z The setup-instance-topology command ran successfully.
```

Verify that all the pods in cpd-operators namespace are running.
```
oc get pods -n ${PROJECT_CPD_INST_OPERATORS}
```

Output:
```
NAME                                                              READY   STATUS      RESTARTS   AGE
503d5c2e46ab6fb9879583798f27c0f918c2ca45266319168e4768e004qx5jg   0/1     Completed   0          6m18s
701ae32f5d73a5c8a48d2e2e3a8a6f0c10bbbd0867279341be83e3ff75fg99j   0/1     Completed   0          5m44s
8d67f73b77c43214c1f31adf025bfc258a4b6d671a34f339926a897eb6vlsph   0/1     Completed   0          4m44s
cloud-native-postgresql-catalog-kldbq                             1/1     Running     0          7m24s
ibm-common-service-operator-574f6cc648-w22jk                      1/1     Running     0          4m32s
ibm-namespace-scope-operator-78bbcccbfb-fz4hd                     1/1     Running     0          6m6s
opencloud-operators-c8h4h                                         1/1     Running     0          7m24s
operand-deployment-lifecycle-manager-55dd656885-djzzq             1/1     Running     0          2m45s
```

### Step 4.7 - Install the operators for your CPD services
Run the apply-olm command to install the operators of all the CPD services that you have specified in the COMPONENTS environments variable.
```
./cpd-cli manage apply-olm --release=${VERSION} --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --components=${COMPONENTS}
```

Output:
```
[SUCCESS] 2023-07-09T10:46:20.497384Z The apply-olm command ran successfully.
```

Verify that all the pods in cpd-operators namespace are running. You will see that many more appear, as we have selected to install the WKC service.
```
oc get pods -n ${PROJECT_CPD_INST_OPERATORS}
```

Output:
```
NAME                                                              READY   STATUS      RESTARTS   AGE
0aa67ed90def8227b3586acd9e0e3424df9a13619e888e0cec2d1bfce7nxdfb   0/1     Completed   0          14m
13e8bc6f0a14d6e08b572c7caecc9a483146293ef76ef175adca3819a9nzr7s   0/1     Completed   0          10m
2a2cbf017bedb7ad8b370e2f28316b3ab571578db6e19fff666f1fdd13z5d5l   0/1     Completed   0          13m
4f2b0ed1d40849c7cd18c8b25544d54d366208632c1d5d5806ef58d6c4wvbcl   0/1     Completed   0          9m30s
503d5c2e46ab6fb9879583798f27c0f918c2ca45266319168e4768e004qx5jg   0/1     Completed   0          35m
52aabca09e60c7a0ef1afafbc2668dc318479fe2bf030190c82764f6f1sdc7n   0/1     Completed   0          12m
55510daecba9864570bd9fd1298f9ad5b3ba9ded1fd68776348477a865svfkl   0/1     Completed   0          12m
701ae32f5d73a5c8a48d2e2e3a8a6f0c10bbbd0867279341be83e3ff75fg99j   0/1     Completed   0          34m
8cbb7183e1db962a6d56e69545537933bfd81965fe001eb47645d4b261898tc   0/1     Completed   0          10m
8d67f73b77c43214c1f31adf025bfc258a4b6d671a34f339926a897eb6vlsph   0/1     Completed   0          33m
91527da88ef5fea4d4708fa852aa7fb946933d2cc538946092fd37a8c5wrqfx   0/1     Completed   0          12m
aa6c20373dcd231b7a303c0b19e73042093aa49d9d248bb9f93a3175c6wzsnh   0/1     Completed   0          21m
ac3d189b4e2c61bb81ca9a3b2a8856ea4c1bc4e94cdb210421bb5c20c385gvc   0/1     Completed   0          13m
apple-fdb-controller-manager-7c5c585c9b-8s5wp                     1/1     Running     0          11m
bf6a00a1ff1a25c93dbe5507b5009e326749f48ec179cdc570015076b5lwlql   0/1     Completed   0          11m
cloud-native-postgresql-catalog-kldbq                             1/1     Running     0          36m
cpd-platform-operator-manager-75d88df68b-84jkk                    1/1     Running     0          21m
cpd-platform-sbj99                                                1/1     Running     0          23m
db2u-day2-ops-controller-manager-7bd5b5dc47-rvw6k                 1/1     Running     0          12m
db2u-operator-manager-f857cb4cb-vc9qc                             1/1     Running     0          12m
e214980dda24b504920f8851f1af9a95e5ccde8e72aa8c9af510fe420cch2m2   0/1     Completed   0          14m
ibm-common-service-operator-574f6cc648-w22jk                      1/1     Running     0          33m
ibm-cpd-ae-operator-5c68bd94fc-pkxzc                              1/1     Running     0          13m
ibm-cpd-ae-operator-catalog-sfmtq                                 1/1     Running     0          16m
ibm-cpd-ccs-operator-59695b747f-c4vwx                             1/1     Running     0          13m
ibm-cpd-ccs-operator-catalog-pzztr                                1/1     Running     0          16m
ibm-cpd-datarefinery-operator-68bf85655d-249n4                    1/1     Running     0          10m
ibm-cpd-datarefinery-operator-catalog-2lrlk                       1/1     Running     0          16m
ibm-cpd-datastage-operator-57877f989c-w8dmq                       1/1     Running     0          11m
ibm-cpd-datastage-operator-catalog-xw46n                          1/1     Running     0          16m
ibm-cpd-wkc-operator-6b455ccbf7-4b4r4                             1/1     Running     0          9m9s
ibm-cpd-wkc-operator-catalog-qjwv7                                1/1     Running     0          16m
ibm-db2aaservice-cp4d-operator-catalog-64g4n                      1/1     Running     0          16m
ibm-db2aaservice-cp4d-operator-controller-manager-644f585cqvdfg   1/1     Running     0          12m
ibm-db2uoperator-catalog-2s7n4                                    1/1     Running     0          16m
ibm-elasticsearch-catalog-tb664                                   1/1     Running     0          16m
ibm-elasticsearch-operator-ibm-es-controller-manager-7dc59ldbcl   1/1     Running     0          13m
ibm-fdb-controller-manager-6b89cd89d9-rb2cb                       1/1     Running     0          11m
ibm-fdb-operator-catalog-45nql                                    1/1     Running     0          16m
ibm-namespace-scope-operator-78bbcccbfb-fz4hd                     1/1     Running     0          35m
manta-adl-operator-catalog-vqj7q                                  1/1     Running     0          16m
manta-adl-operator-controller-manager-5bf4c86866-nx2lk            1/1     Running     0          9m10s
opencloud-operators-c8h4h                                         1/1     Running     0          36m
operand-deployment-lifecycle-manager-55dd656885-djzzq             1/1     Running     0          31m
```

### Step 4.8 - Install the CPD services by running the apply-cr command.
Note, that this command eventually takes 2 hours to complete due to the large number of services that will be installed when installing WKC.
```
./cpd-cli manage apply-cr \
--release=${VERSION} \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--components=${COMPONENTS} \
--block_storage_class=${STG_CLASS_BLOCK} \
--file_storage_class=${STG_CLASS_FILE} \
--license_acceptance=true \
-v
```

Output:
```
TASK [utils : check if CR status indicates completion for ibmcpd-cr in zen, max retry 25 times 300s delay] *****************************************************************
Not ready yet - Retrying: check if CR status indicates completion for ibmcpd-cr in zen, max retry 25 times 300s delay (25 Retries left)
Not ready yet - Retrying: check if CR status indicates completion for ibmcpd-cr in zen, max retry 25 times 300s delay (24 Retries left)
Not ready yet - Retrying: check if CR status indicates completion for ibmcpd-cr in zen, max retry 25 times 300s delay (23 Retries left)
Not ready yet - Retrying: check if CR status indicates completion for ibmcpd-cr in zen, max retry 25 times 300s delay (22 Retries left)
```

Open a second SSH session to watch the installation progressing. You will need to wait 5-10 minuted until the first pods will startup in the CPD instance namespace, that this command monitors:
```
watch -n 10 "oc get pods -n ${PROJECT_CPD_INST_OPERANDS} --sort-by=.status.startTime | tac"
```

Output:
```
Every 10.0s: oc get pods -n zen                                                                                                    bastion-gym-lan: Sun Jul  9 11:27:10 2023

NAME                                   READY   STATUS              RESTARTS   AGE
create-secrets-job-l6mj6               0/1     Completed           0          6m58s
usermgmt-645b6ff96c-2sjx4              1/1     Running             0          2m25s
usermgmt-645b6ff96c-kvk5z              1/1     Running             0          2m25s
usermgmt-ensure-tables-job-grf48       0/1     Completed           0          3m50s
zen-core-create-tables-job-x6swp       0/1     Completed           0          3m
zen-core-pre-requisite-job-pz5jh       0/1     ContainerCreating   0          4s
zen-metastore-edb-1                    1/1     Running             0          5m8s
zen-metastore-edb-2                    1/1     Running             0          4m40s
zen-minio-0                            1/1     Running             0          8m26s
zen-minio-1                            1/1     Running             0          8m26s
zen-minio-2                            1/1     Running             0          8m26s
zen-minio-create-buckets-job-56m67     0/1     Completed           0          7m14s
zen-pre-requisite-job-stm5v            0/1     Completed           0          39s
zen-watchdog-create-tables-job-kx7r8   0/1     Completed           0          2m44s
```

Output (after WKC instllation completed):
```
[SUCCESS] 2023-07-09T12:52:57.520771Z The apply-cr command ran successfully.
```

Footprint after WKC installation:
```
  cpu                21772m (34%)   109685m (172%)
  memory             79908Mi (31%)  244144Mi (95%)
```

Ouput of pods in cpd instance namespace:

```
NAME                                                              READY   STATUS      RESTARTS       AGE
asset-files-api-d97684485-q595t                                   1/1     Running     0              71m
ax-environments-api-deploy-7cd644644-jxpx4                        1/1     Running     0              65m
ax-environments-ui-deploy-7d5767dd6b-j2cj2                        1/1     Running     0              65m
c-db2oltp-wkc-db2u-0                                              1/1     Running     0              53m
c-db2oltp-wkc-instdb-5qjlq                                        0/1     Completed   0              76m
catalog-api-6f55966485-h88d5                                      1/1     Running     0              77m
catalog-api-6f55966485-rnt6l                                      1/1     Running     0              77m
ccs-post-install-job-k49jw                                        0/1     Completed   0              53m
conn-home-pre-install-job-pcrwr                                   0/1     Completed   0              77m
connect-sdk-init-nh855                                            0/1     Completed   0              78m
copy-scheduler-runtime-def-job-5wg2w                              0/1     Completed   0              63m
create-dap-directories-fzmr7                                      0/1     Completed   0              73m
create-secrets-job-l6mj6                                          0/1     Completed   0              114m
dap-base-extension-translations-5nqv9                             0/1     Completed   0              72m
dataview-api-service-7bc54ff9b6-q7lbr                             1/1     Running     0              61m
dc-main-7b8d97559-4ct4l                                           1/1     Running     0              76m
dp-transform-7cdd4dc979-8hnhd                                     1/1     Running     0              33m
dsx-requisite-pre-install-job-fzchx                               0/1     Completed   0              86m
elasticsea-0ac3-ib-6fb9-es-server-esnodes-0                       2/2     Running     0              80m
elasticsea-0ac3-ib-6fb9-es-server-esnodes-1                       2/2     Running     0              80m
elasticsea-0ac3-ib-6fb9-es-server-esnodes-2                       2/2     Running     0              80m
elasticsearch-master-ibm-elasticsearch-create-snapshot-repn6sqz   0/1     Completed   0              110s
env-spec-sync-job-28148710-t5jdl                                  0/1     Completed   0              4m58s
environments-init-job-zh6z2                                       0/1     Completed   0              66m
event-logger-api-7d9994df9f-5f62z                                 1/1     Running     0              71m
finley-public-f4764cffd-5brgb                                     1/1     Running     0              34m
ibm-nginx-687bc86bc5-vgbz5                                        2/2     Running     0              103m
ibm-nginx-687bc86bc5-zq5b6                                        2/2     Running     0              103m
ibm-nginx-tester-76c7f75677-8ktwt                                 2/2     Running     0              103m
jdbc-driver-sync-job-28148710-zqgn8                               0/1     Completed   0              4m58s
jobs-api-5d9f6b75f8-d792x                                         1/1     Running     0              63m
jobs-ui-658b57cc9b-85hpk                                          1/1     Running     0              63m
jobs-ui-extension-translations-8knkj                              0/1     Completed   0              63m
knowledge-accelerators-566b78dcc-crxkn                            1/1     Running     0              33m
metadata-discovery-66665c4c75-ppkp4                               1/1     Running     0              34m
ngp-projects-api-5f679f5fc6-4kdmj                                 1/1     Running     0              71m
portal-catalog-766567f6fd-lpmzr                                   1/1     Running     0              76m
portal-common-api-566697c7bb-h8xkr                                1/1     Running     0              37m
portal-job-manager-7cb996f8c8-8pgpr                               1/1     Running     0              71m
portal-main-545667b8f7-9r98f                                      1/1     Running     0              72m
portal-notifications-54458546cb-94qtx                             1/1     Running     0              71m
portal-projects-75f8b7cb44-4t8wf                                  1/1     Running     0              71m
post-install-upgrade-spaces-wml-global-asset-type-hh5rg           0/1     Completed   0              55m
projects-ui-refresh-users-fx2sd                                   0/1     Completed   0              71m
rabbitmq-ha-0                                                     1/1     Running     0              85m
rabbitmq-ha-1                                                     1/1     Running     0              83m
rabbitmq-ha-2                                                     1/1     Running     0              83m
redis-ha-haproxy-66f979d965-lnsvs                                 1/1     Running     0              85m
redis-ha-server-0                                                 2/2     Running     0              85m
redis-ha-server-1                                                 2/2     Running     0              84m
redis-ha-server-2                                                 2/2     Running     0              84m
runtime-assemblies-operator-7cfbd56-n2xks                         1/1     Running     0              70m
runtime-manager-api-775dc8bb66-qj8hj                              1/1     Running     0              70m
runtime-manager-upgrade-job-4gcfm                                 0/1     Completed   0              54m
scheduler-rtm-upgrade-job-4lwz4                                   0/1     Completed   0              53m
spaces-86bb5cf498-wl27d                                           1/1     Running     0              61m
spaces-ui-extension-translations-kf4vv                            0/1     Completed   0              63m
spaces-ui-refresh-users-rc7b9                                     0/1     Completed   0              62m
spark-hb-br-recovery-7d6dfb9fd9-8qzsk                             1/1     Running     0              72m
spark-hb-cloud-native-postgresql-1                                1/1     Running     0              85m
spark-hb-cloud-native-postgresql-2                                1/1     Running     0              84m
spark-hb-control-plane-75b9695464-hhpcz                           2/2     Running     0              74m
spark-hb-create-meta-store-client-secret-rjcft                    0/1     Completed   0              84m
spark-hb-create-trust-store-68b6bc57d9-wn65q                      1/1     Running     0              79m
spark-hb-deployer-agent-597f665dfd-np7xk                          2/2     Running     0              74m
spark-hb-kernel-cleanup-cron-28148700-vnbrr                       0/1     Completed   0              14m
spark-hb-load-postgres-db-specs-sfmpr                             0/1     Completed   0              78m
spark-hb-nginx-7cd7c455dc-l5pw2                                   1/1     Running     0              74m
spark-hb-register-hb-dataplane-7cb5f54475-vd8zn                   1/1     Running     0              50m
usermgmt-645b6ff96c-2sjx4                                         1/1     Running     0              110m
usermgmt-645b6ff96c-kvk5z                                         1/1     Running     0              110m
usermgmt-ensure-tables-job-grf48                                  0/1     Completed   0              111m
volumes-profstgintrnl-deploy-f6985c585-8vt66                      1/1     Running     0              36m
volumes-profstgintrnl-start-file-server-job-6s5m4                 0/1     Completed   0              36m
wdp-connect-connection-bbb767cc-kwbwf                             1/1     Running     0              77m
wdp-connect-connector-68b565d64d-bmgm2                            1/1     Running     0              77m
wdp-connect-flight-bbd56f85c-mgt4c                                1/1     Running     0              77m
wdp-couchdb-0                                                     2/2     Running     0              85m
wdp-couchdb-1                                                     2/2     Running     0              85m
wdp-couchdb-2                                                     2/2     Running     0              85m
wdp-dataprep-559b4b4468-h7r9k                                     1/1     Running     0              44m
wdp-dataview-565d9ffccd-xh9gx                                     1/1     Running     0              61m
wdp-lineage-bf9c9f75-txqlt                                        1/1     Running     0              34m
wdp-policy-service-5d5568749b-pc6sb                               1/1     Running     0              34m
wdp-profiling-84494cc588-s5zpn                                    1/1     Running     0              34m
wdp-profiling-iae-init-bqp8t                                      0/1     Completed   0              36m
wdp-profiling-messaging-84bb69bf4d-d89mt                          1/1     Running     0              34m
wdp-profiling-ui-747df6f5d-vz2gt                                  1/1     Running     0              34m
wdp-search-55868969b-rsljt                                        1/1     Running     0              34m
wdp-shaper-56744d4db4-h7r9p                                       1/1     Running     0              44m
wkc-base-roles-init-vgb4w                                         0/1     Completed   0              76m
wkc-bi-data-service-b6d676587-zvz6r                               1/1     Running     0              34m
wkc-catalog-api-jobs-6f5fb54446-hkpjz                             1/1     Running     0              33m
wkc-data-rules-967d6f5f9-645sv                                    1/1     Running     0              33m
wkc-db2u-init-2cn9w                                               0/1     Error       0              76m
wkc-db2u-init-jxgc6                                               0/1     Completed   0              39m
wkc-extensions-translations-init-95626                            0/1     Completed   0              75m
wkc-glossary-service-6b5c77f686-pv6w8                             1/1     Running     0              34m
wkc-glossary-service-sync-cronjob-28148701-mt4wc                  0/1     Completed   0              13m
wkc-gov-ui-6bffbbd69d-x6fqf                                       1/1     Running     0              34m
wkc-mde-service-manager-57d68d44dd-2r5t5                          1/1     Running     0              33m
wkc-metadata-imports-ui-6f96d9575f-kk9jc                          1/1     Running     0              34m
wkc-post-install-init-s9vf5                                       0/1     Completed   0              28m
wkc-roles-init-hzppg                                              0/1     Completed   0              37m
wkc-search-7fd4b8d999-d94cf                                       1/1     Running     0              76m
wkc-term-assignment-56b6f866d9-wrgnk                              1/1     Running     0              33m
wkc-workflow-service-7677ddcf48-srjmw                             1/1     Running     0              34m
wml-main-85bd4cd65f-tplbs                                         1/1     Running     0              63m
zen-audit-d8588b7cd-7vqkz                                         1/1     Running     0              105m
zen-core-66c5449cb4-tqb2m                                         2/2     Running     1 (104m ago)   105m
zen-core-66c5449cb4-xt74q                                         2/2     Running     1 (104m ago)   105m
zen-core-api-69f544bbd-dzzvz                                      2/2     Running     0              105m
zen-core-api-69f544bbd-tfp2v                                      2/2     Running     0              105m
zen-core-create-tables-job-x6swp                                  0/1     Completed   0              110m
zen-core-pre-requisite-job-pz5jh                                  0/1     Completed   0              107m
zen-database-core-c9f8996cb-9sp2n                                 1/1     Running     0              83m
zen-databases-94c7bb886-9sg9n                                     1/1     Running     0              83m
zen-databases-94c7bb886-m2wxf                                     1/1     Running     0              83m
zen-metastore-backup-cron-job-28148640-zz2sx                      0/1     Completed   0              74m
zen-metastore-edb-1                                               1/1     Running     0              112m
zen-metastore-edb-2                                               1/1     Running     0              112m
zen-minio-0                                                       1/1     Running     0              116m
zen-minio-1                                                       1/1     Running     0              116m
zen-minio-2                                                       1/1     Running     0              116m
zen-minio-create-buckets-job-56m67                                0/1     Completed   0              115m
zen-pre-requisite-job-stm5v                                       0/1     Completed   0              108m
zen-watchdog-create-tables-job-kx7r8                              0/1     Completed   0              110m
zen-watchdog-dd5d96d6f-58nwl                                      1/1     Running     0              98m
zen-watchdog-post-requisite-job-hwrcp                             0/1     Completed   0              98m
zen-watchdog-pre-requisite-job-7ksrd                              0/1     Completed   0              98m
zen-watcher-548d7d5b56-nsr6w                                      2/2     Running     0              37m
```

# 5. Post-installation steps

### Step 5.1 - Retrieving the default CPD admin password
```
oc extract -n ${PROJECT_CPD_INST_OPERANDS} secret/admin-user-details --to=-
```

### Step 5.2 - Retrieving the CPD web console URL
```
oc get routes -A | grep cpd | awk '{print "https://" $3}'
```

### Step 5.3 - Measuring the footprint
```
oc get nodes | grep -e "cpu  " -e "memory  "
```

### Step 5.4 - Logging in to the SNO node
```
oc debug node/master-1
```

### Step 5.5 - Enabling optional WKC features
This will enable the Knowledge Graph, Data Quality and MANTA services in the WKC instance.
```
./cpd-cli manage update-cr \
--component=wkc \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--patch="{\"enableKnowledgeGraph\":True,\"enableDataQuality\":True,\"enableMANTA\":True}"
```

Output:
```
[SUCCESS] 2023-07-09T14:46:37.122056Z The update-cr command ran successfully.
```

### Step 5.6 - Enable Watson NLP
```
oc patch -n ${PROJECT_CPD_INST_OPERANDS} NotebookRuntime ibm-cpd-ws-runtime-231-py --type=merge --patch '{"spec":{"install_nlp_models":true}}'
```

Verify Watson NLP.
```
oc get -n ${PROJECT_CPD_INST_OPERANDS} NotebookRuntime -o custom-columns=NAME:metadata.name,NLP:spec.install_nlp_models,STATUS:status.runtimeStatus
```

# 6. Troubleshooting
If you are experiencing problems with accessing the SNO cluster via oc login commands, for example getting an EOF error, it might help to reboot the SNO node.

### Step 6.1 - Rebooting the SNO worker node
You can ssh to the SNO node from your bastion and then rebooting the node.
```
ssh core@192.168.252.11 -i /tmp/ocp/cluster/id_rsa
sudo su -
shutdown -Fr now
```

# 7. Setting up Minio S3 on SNO
This explains how to setup a Minio S3 cluster on the SNO node.

Assumes that:
- you are logged in as kubeadmin to your OpenShift cluster
- you can pull images from Dockerhub
- you have a storage class nfs-storage-provisioner

### Step 7.1 - Download Velero archive
```
wget https://github.com/vmware-tanzu/velero/releases/download/v1.6.0/velero-v1.6.0-linux-amd64.tar.gz
```

### Step 7.2 - Extract Velero archive
```
tar xvzf velero-v1.6.0-linux-amd64.tar.gz
mv velero-v1.6.0-linux-amd64/* .
rm -rf velero-v1.6.0-linux-amd64
rm -rf velero-v1.6.0-linux-amd64.tar.gz
```

### Step 7.3 - Create Minio deployment
```
oc apply -f examples/minio/00-minio-deployment.yaml
```

### Step 7.4 - Patch Minio image
```
oc set image deployment/minio minio=minio/minio:RELEASE.2021-04-22T15-44-28Z -n velero
```

### Step 7.5 - Create PVCs for Minio and modify the Minio deployment
Create the following PersitentVolumeClaim and save the YAML in the minio-config-pvc.yaml file
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: velero
  name: minio-config-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-storage-provisioner
 ```
 
Create another PersistentVolumeClaim and save the YAML in the minio-storage-pvc.yaml file
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: velero
  name: minio-storage-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 400Gi
  storageClassName: nfs-storage-provisioner
```

Apply the two YAML files and modify the Minio deployment, so that the new PVCs are taken into account
```
oc apply -f minio-config-pvc.yaml
oc apply -f minio-storage-pvc.yaml
oc set volume deployment.apps/minio --add --overwrite --name=config --mount-path=/config --type=persistentVolumeClaim --claim-name="minio-config-pvc" -n velero
oc set volume deployment.apps/minio --add --overwrite --name=storage --mount-path=/storage --type=persistentVolumeClaim --claim-name="minio-storage-pvc" -n velero
```

### Step 7.6 - Set Minio resource limits
Set resouce limits for Minio
```
oc set resources deployment minio -n velero --requests=cpu=500m,memory=256Mi --limits=cpu=1,memory=1Gi
```

### Step 7.7 - Expose Minio service
Expore Minio service
```
oc expose svc minio -n velero
```

### Step 7.8 - Create Ingress for Minio
Create the following Ingress and save the YAML in the minio-ingress.yaml file
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minio
spec:
  rules:
  - host: minio-velero.apps.cp4d.mop
    http:
      paths:
      - backend:
          # Forward to a Service called 'minio'
          service:
            name: minio
            port:
              number: 9000
        path: /
        pathType: Exact
 ```
 
 Apply the YAML to create the Ingress for Minio on your cluster.
 ```
 oc apply -f minio-ingress.yaml
 ```
 
 ### Step 7.9 - Get the Minio URL
 ```
 oc get route minio -n velero
 ```



# END OF DOCUMENT