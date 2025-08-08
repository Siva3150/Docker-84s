#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

# docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
VALIDATE $? "Docker installation"

# eksctl
# ARCH=amd64
# PLATFORM=$(uname -s)_$ARCH
# curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
# curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check
# tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
# sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl
# mv /tmp/eksctl /usr/local/bin
# eksctl version
# VALIDATE $? "eksctl installation"

# eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt" | grep $PLATFORM | sha256sum --check

# Extract and move binary
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
VALIDATE $? "eksctl installation"



# kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.0/2024-09-12/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv kubectl /usr/local/bin/kubectl
VALIDATE $? "kubectl installation"

# # kubens
# git clone https://github.com/ahmetb/kubectx /opt/kubectx
# ln -s /opt/kubectx/kubens /usr/local/bin/kubens
# VALIDATE $? "kubens installation"

rm -rf /opt/kubectx
git clone https://github.com/ahmetb/kubectx /opt/kubectx

rm -f /usr/local/bin/kubens
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
VALIDATE $? "kubens installation"



#  #Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 
# chmod 700 get_helm.sh
# ./get_helm.sh VALIDATE $? "helm installation"

# # Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh
# VALIDATE $? "helm installation"

# # Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh

# # Run the install
# ./get_helm.sh

# # Ensure /usr/local/bin is in PATH (in case it's not)
# export PATH=$PATH:/usr/local/bin

# # Check if helm is really installed
# if command -v helm &>/dev/null; then
#   VALIDATE 0 "helm installation"
# else
#   VALIDATE 1 "helm installation"
# fi

# # Ensure /usr/local/bin is in PATH
# export PATH=$PATH:/usr/local/bin
# hash -r

# # Check if helm is really installed
# if command -v helm &>/dev/null; then
#   VALIDATE 0 "helm installation"
# else
#   VALIDATE 1 "helm installation"
# fi

# Helm (manual install to avoid PATH issues in get_helm.sh)
HELM_VERSION="v3.18.4"

# Make sure PATH is correct before install
export PATH=$PATH:/usr/local/bin
hash -r

curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
rm -rf linux-amd64 helm.tar.gz

VALIDATE $? "helm installation"

# Persist PATH for future sessions
if ! grep -q "/usr/local/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
fi

# Double-check Helm works now
if ! command -v helm >/dev/null 2>&1; then
    echo "Helm still not found. Please run: source ~/.bashrc"
    exit 1
fi
