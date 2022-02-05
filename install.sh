#!/bin/sh

SRC_CODE="./src_code"
INVENTORY_FILE="./inventory.ini"

cloneRepo()
{

    if command -v git
    then
        echo "command git exists on system"
    else
        echo "git could not be found"
        echo "Installing GIT..."
        apt -qq -y update
        apt -qq -y install git
    fi
    echo "Enter the repository containing the source code: "
    read -r REPO
    echo "Cloning from $REPO into local directory $SRC_CODE"
    git clone -q "$REPO" "$SRC_CODE"
    echo "Source Code cloned successfully"
}

installDependencies()
{
    if command -v ansible-playbook
    then
        echo "Ansible exists on your system"
    else
        echo "Unable to find  ansible"
        echo "Installing Ansbile"
        apt -qq -y update
        apt -qq install software-properties-common
        add-apt-repository -qq --yes --update ppa:ansible/ansible
        apt -qq install ansible
    fi
#    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/docker-registry/playbook.yml
#    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/elastic-search/playbook.yml
#    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/redis/playbook.yml
#    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/kafka-zookeeper/playbook.yml
    # ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/kubernetes/playbook.yml
   ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvv  -i "$INVENTORY_FILE" ./ansible-cookbooks/postgres-etcd/deploy_pgcluster.yml
}

installDependencies