# Workstation setup
Create a VM in IBM Cloud or on a local Workstation the environment for the Installation. I have choosen UBUNTU LTS as a installer environment. 
The VM needs a docker or podman environment for the cpd-installer. 

## Install oh-my-zsh
install the zsh environmen as a default shell 

sudo apt-get update
sudo apt install zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## Install Docker on the workstaion
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

## Install IBM Cloud CLI

curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

ibmcloud plugin install container-service
ibmcloud plugin install container-registry
ibmcloud plugin install schematics

## Install the OC CLI

https://docs.openshift.com/container-platform/4.11/cli_reference/openshift_cli/getting-started-cli.html#cli-installing-cli_cli-developer-commands


## Get the CPD CLI
check if newer version of cpd-cli is release - download the corresponding to your cpd-cluster version

wget https://github.com/IBM/cpd-cli/releases/download/v12.0.2/cpd-cli-linux-EE-12.0.2.tgz

mkdir -p $HOME/.local/bin
cd $HOME/.local
tar -xvzf $HOME/cpd-cli-linux-EE-12.0.2.tgz

sudo usermod -aG docker cloudpakclassic

## Append to .zshrc
enhance .bashrc or .zshrc with the customization for the CLIs 

copy the add_to_zshrc.sh into the local .zshrc or .bashrc - modify the path to the cpd-demo-env.sh file

source ~/.zshrc

## Optional

### HELM
curl -sL https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

### kubectl

curl --progress-bar -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

### additional plugins
ibmcloud plugin repo-plugins
