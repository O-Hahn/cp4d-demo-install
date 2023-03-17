#!/bin/bash
# You need to login to some Linux server where you can the following command.
# If you don’t’ use https://cloud.ibm.com/shell, you need to install ibmcloud cli and login by "ibmcloud login --sso"
# $OCP_URL, $OCP_TOKEN, $OCP_VPC and $IBM_ENTITLEMENT_KEY should be set prior to execute commands

oc login --token=$OCP_TOKEN --server=$OCP_URL

b64_credential=`echo -n "cp:$IBM_ENTITLEMENT_KEY" | base64 -w0`
rm -f .dockerconfigjson

oc extract secret/pull-secret -n openshift-config

if [ "$(cat .dockerconfigjson)" = "" ]; then 
  echo "creating new .dockerconfigjson"
  oc create secret docker-registry --docker-server=cp.icr.io --docker-username=cp \
    --docker-password=$IBM_ENTITLEMENT_KEY --docker-email="fyre@us.ibm.com" -n openshift-config pull-secret
  oc extract secret/pull-secret -n openshift-config
fi

if [ "$(cat .dockerconfigjson  | grep '.auths' | grep 'cp.icr.io')" = "" ]; then
  echo "updating .dockerconfigjson"
  sed -i -e 's|:{|:{"cp.icr.io":{"auth":"'$b64_credential'"\},|' .dockerconfigjson
fi

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=./.dockerconfigjson

sleep 30

ibmcloud oc worker ls -c $OCP_VPC
workers=$(ibmcloud oc worker ls -c $OCP_VPC -q | awk '{print $1}')

for wid in $workers;
do 
  echo -e "Relplacing worker $wid in cluster $OCP_VPC \n"
  ibmcloud oc worker replace -c $OCP_VPC -w $wid -f
done
