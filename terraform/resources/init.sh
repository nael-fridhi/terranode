#!/usr/bin/env bash



#######################################################
# Configuration of the instance
#######################################################
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ./jq
sudo cp jq /usr/bin

REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
VOLUME_ID=`aws --region $${REGION} \
  ec2 describe-volumes \
  --filter "Name=attachment.instance-id, Values=$${INSTANCE_ID}" \
  --query "Volumes[].VolumeId" --out text`
NETWORK_ID=`aws --region $${REGION} \
  ec2 describe-network-interfaces \
  --filter "Name=attachment.instance-id, Values=$${INSTANCE_ID}" \
  --query "NetworkInterfaces[].NetworkInterfaceId" --out text`

aws --region $${REGION} ec2 create-tags --resources $${VOLUME_ID} --tags Key=Name,Value="${name}-ebs"
aws --region $${REGION} ec2 create-tags --resources $${NETWORK_ID} --tags Key=Name,Value="${name}-eni"
aws --region $${REGION} ec2 create-tags --resources $${VOLUME_ID} $${NETWORK_ID} --tags Key=Environment,Value="${environment}"
aws --region $${REGION} ec2 create-tags --resources $${VOLUME_ID} $${NETWORK_ID} --tags Key=Terraform,Value="True"
aws --region $${REGION} ec2 create-tags --resources $${VOLUME_ID} $${NETWORK_ID} --tags Key=Application,Value="${application}"
aws --region $${REGION} ec2 create-tags --resources $${VOLUME_ID} $${NETWORK_ID} --tags Key=Contact,Value="${contact}"

#install SSM
mkdir /tmp/ssm
cd /tmp/ssm
sudo yum install wget -y
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo rpm --install amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
cd ..
rm -rf /tmp/ssm/

#install unzip glibc-devel libaio python3
sudo yum install unzip glibc-devel libaio python3 -y

#install aws cli
mkdir /tmp/aws
cd /tmp/aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf /tmp/aws/

#install python3 and pip3
sudo pip3 install boto3
sudo pip3 install ansible
sudo ln -s /usr/local/bin/ansible-playbook /usr/bin/ansible-playbook

########################################################################
# Prerequisites Installtion For configuring Terra Node
########################################################################
# 1. Download the archive
wget https://go.dev/dl/go1.17.1.linux-amd64.tar.gz
# Optional: remove previous /go files:
sudo rm -rf /usr/local/go
# 2. Unpack:
sudo tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
# 3. Add the path to the go-binary to your system path:
# (for this to persist, add this line to your ~/.profile or ~/.bashrc or  ~/.zshrc)
export PATH=$PATH:/usr/local/go/bin
# 4. Verify your installation:
go version
# go version go1.17.1 linux/amd64

# Install make & gcc
sudo apt-get update
sudo apt-get install make
sudo apt-get install gcc

########################################################################
# Terra core installation
########################################################################

git clone https://github.com/terra-money/core
cd core
git checkout v0.5.18
make install # We can export to disable ledger support: export LEDGER_ENABLED=false
export PATH=$PATH:$(go env GOPATH)/bin



########################################################################
# Terra core Configuration
########################################################################


# Add this two lines to the file: /etc/security/limits.conf
# *                soft    nofile          65535 
# *                hard    nofile          65535  

# minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb,1.25usek,1.25unok,0.9udkk,2180.0uidr,7.6uphp,1.17uhkd"
# Enable defines if the API server should be enabled: enable = true


########################################################################
# FCD Configuration
########################################################################

