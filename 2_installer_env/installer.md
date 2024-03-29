# Workstation/BridgeHeadServer setup
Create a VM in IBM Cloud or on a local Workstation the environment for the Installation. I have choosen UBUNTU LTS as a installer environment.

The VM needs a docker or podman environment for the cpd-installer. 

## running on bridgehead server 
if running the bridgehead server environment - start with the terraform script - this will create the whole VPC with bridgehead and OCP Cluster base.

### create ssh-key for the Server (if running bridgehead)
mkdir ssh-key
cd ssh-key

ssh-keygen -t ed25519 -b 4096 -C "cpd-admin"
ibmcloud is key-create cp4d-admin @cpdadmin-id_ed25519.pub --resource-group-name demo --key-type ed25519

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


### Install IBM Cloud Dev Environment
curl -sL https://ibm.biz/idt-installer | bash


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


### Install IBM Cloud CLI

curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

ibmcloud plugin install container-service
ibmcloud plugin install container-registry
ibmcloud plugin install schematics
ibmcloud plugin install vpc-infrastructure

## Install the OC CLI

https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html#cli-installing-cli_cli-developer-commands

wget https://downloads-openshift-console.SERVERNAME.eu-de.containers.appdomain.cloud/amd64/linux/oc.tar
tar xvf oc.tar
mv oc /usr/local/bin

## Install ITZ Integration-CLI
curl https://raw.githubusercontent.com/cloud-native-toolkit/itzcli/main/scripts/install.sh | bash -

on Mac:
brew tap cloud-native-toolkit/homebrew-techzone
brew install itz

## Cloud-Native-Toolkit
see: https://develop.cloudnativetoolkit.dev/setup/fast-start/

curl -sfL get.cloudnativetoolkit.dev | sh -


## Get the CPD CLI
check if newer version of cpd-cli is release - download the corresponding to your cpd-cluster version
https://github.com/IBM/cpd-cli/releases

wget https://github.com/IBM/cpd-cli/releases/download/v13.0.2/cpd-cli-linux-EE-13.0.2.tgz

mkdir ~/Git
mkdir ~/Git/cpd-cli
tar xvf cpd-cli-linux-EE-13.0.2.tgz 
mv cpd-cli-linux-EE-13.0.2-26/* ~/Git/cpd-cli

mkdir -p $HOME/.local/bin
cd $HOME/.local

sudo usermod -aG docker cloudpakclassic

## Terraform 
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

## Git clone of cp4d-demo-install
mkdir Git
cd Git
git clone https://github.com/O-Hahn/cp4d-demo-install.git

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
