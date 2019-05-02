#!/bin/bash

cd terraform

echo "Creating Resources"
terraform apply

#echo "Fetching Instance IP"
#newip=`terraform output -json public_ip | jq -r '.value'`

#echo $newip

#echo "updating Ansible Inventory" 

#sed -i "2s/.*/$newip/" ansible/hosts/hosts
#echo [aws] > ansible/hosts/hosts
#echo $newip >> ansible/hosts/hosts

echo "Running Ansible playbooks"
cd ansible

ansible-playbook runsetup.yml


