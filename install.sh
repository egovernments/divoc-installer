#!/bin/sh

cloneRepo()
{
    SRC_CODE="./src_code"

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
#     echo "Enter path to inventory file: "
#     read -r INVENTORY_FILE
#    ansible-playbook -vvv -i ./inventory ./ansible-cookbooks/docker-registry/playbook.yml
#    ansible-playbook -vvv -i ./inventory ./ansible-cookbooks/elastic-search/playbook.yml
#    ansible-playbook -vvv -i ./inventory ./ansible-cookbooks/redis/playbook.yml
#    ansible-playbook -vvv -i ./inventory ./ansible-cookbooks/kafka-zookeeper/playbook.yml
#    ansible-playbook -vvv -i ./inventory ./ansible-cookbooks/kubernetes/playbook.yml
    ansible-playbook  -i ./inventory ./ansible-cookbooks/postgres-etcd/etcd_cluster.yml
}

installDependencies