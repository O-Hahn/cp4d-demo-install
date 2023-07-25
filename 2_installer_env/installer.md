# Workstation/BridgeHeadServer setup
Create a VM in IBM Cloud or on a local Workstation the environment for the Installation. I have choosen UBUNTU LTS as a installer environment.

The VM needs a docker or podman environment for the cpd-installer. 

## running on bridgehead server 
if running the bridgehead server environment - start with the terraform script - this will create the whole VPC with bridgehead and OCP Cluster base.

### create ssh-key for the Server (if running bridgehead)
mkdir ssh-key
cd ssh-key

ssh-keygen -t ed25519 -b 4096 -C "cpd-admin"
ibmcloud is key-create cpd-admin @cpdadmin-id_ed25519.pub --resource-group-name demo --key-type ed25519

### Update most current release
ssh -i ssh-key/cpdadmin-id_ed25519 root@<public IP from cpd-bridgehead Server>

### Disk expansion

find the additional 2T Disk
lsblk

fdisk --> press n, press p, returns through defaults, press w 
fdisk /dev/vdd

create disk
/sbin/mkfs -t ext4 /dev/vdd1

cat /etc/fstab 

disk_partition=/dev/vdd1
 uuid=$(blkid -sUUID -ovalue $disk_partition)
 mount_point=$mount_parent/$uuid
 echo "UUID=$uuid $mount_point ext4 defaults,relatime 0 0" >> /etc/fstab

mkdir /cpd-data
mount /dev/vdd1 /cpd-data

## Install additions - based on local or bridgehead server

### Install oh-my-zsh
install the zsh environmen as a default shell 

sudo apt-get update
sudo apt install zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

### Install Docker on the workstaion
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg   

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER

newgrp docker

docker run hello-world

sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R

sudo reboot

### Install IBM Cloud Dev Environment
curl -sL https://ibm.biz/idt-installer | bash

### Install IBM Cloud CLI

curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

ibmcloud plugin install container-service
ibmcloud plugin install container-registry
ibmcloud plugin install schematics

## Install the OC CLI

https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html#cli-installing-cli_cli-developer-commands

wget https://downloads-openshift-console.SERVERNAME.eu-de.containers.appdomain.cloud/amd64/linux/oc.tar
tar xvf oc.tar
mv oc /usr/local/bin

## Get the CPD CLI
check if newer version of cpd-cli is release - download the corresponding to your cpd-cluster version

wget https://github.com/IBM/cpd-cli/releases/cpd-cli-linux-EE-12.0.6.tgz

mkdir -p $HOME/.local/bin
cd $HOME/.local

sudo usermod -aG docker cloudpakclassic

## Terraform 
sudo apt install  software-properties-common gnupg2 curl
curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor > hashicorp.gpg

sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt install terraform

## Append to .zshrc
enhance .bashrc or .zshrc with the customization for the CLIs 

copy the add_to_zshrc.sh into the local .zshrc or .bashrc - modify the path to the cpd-demo-env.sh file

source ~/.zshrc
source

## Optional


### HELM
curl -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

### kubectl

curl --progress-bar -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

### additional plugins install
ibmcloud plugin repo-plugins
