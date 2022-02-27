#!/bin/sh

INVENTORY_FILE="./inventory.ini"

installDependencies()
{
    echo "Installing SSHPASS"
    apt -qq -y update
    apt -qq -y install sshpass

    if command -v ansible-playbook
    then
        echo "Ansible exists on your system"
    else
        echo "Unable to find  ansible"
        echo "Installing Ansbile"
        apt -qq -y update
        apt -qq install software-properties-common
        add-apt-repository -qq --yes --update ppa:ansible/ansible
        apt -qq -y install ansible
    fi
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/docker-registry/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/elastic-search/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/redis/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root ./ansible-cookbooks/kafka-zookeeper/kafka_and_zookeeper.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/kubernetes/cluster.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/postgres-etcd/deploy_pgcluster.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/clickhouse/playbook.yml
}


installKubectl()
{
    if command -v kubectl
    then
        echo "Kubectl exists on your system"
    else
        echo "Installing Kubectl"
        apt -qq -y update
        apt install -y apt-transport-https ca-certificates curl
        curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        apt -qq -y update
        apt -qq -y install kubectl
    fi
}

echo "Starting to install software"
date
installDependencies
installKubectl
echo "Installation Completed"
date