#! /bin/bash

#This file is invokes via init.sh
##Create infrastructure and inventory file
log "===Infrastructure preperation script - cluster-create.sh Initiated==="
log "Start creating infrastructure with Terraform"
cd $script_path
terraform apply 

##Run Ansible configurations
log "Quick sleep while instances start and SSH is ready to serve"
sleep 60
log "Ansible provisioning started"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i $script_path/kargo/inventory/inventory -u core -b $script_path/kargo/cluster.yml


