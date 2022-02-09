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
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/docker-registry/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/elastic-search/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/redis/playbook.yml
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" ./ansible-cookbooks/kafka-zookeeper/kafka_and_zookeeper.yml
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

configureKubectl()
{
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/configuration/playbook.yml
    echo "Enter the IP Address of the Kubernetes master node / control plane: "
    read -r KUBE_NODE
    echo "Enter path to the private key to access the Kubernetes master node / control plane"
    read -r KUBE_NODE_KEY_PATH
    mkdir -p ~/.kube
    scp -i "$KUBE_NODE_KEY_PATH" ubuntu@"$KUBE_NODE":~/kubeadmin.conf ~/.kube/config
    sed -i 's/127.0.0.1/'"$KUBE_NODE"'/g' ~/.kube/config

}

deployCodeOnKube()
{
    kubectl create namespace divoc

    kubectl apply -f kube-deployment-config/divoc-config.yaml -n divoc
    # Keycloak
    kubectl apply -f kube-deployment-config/keycloak-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/keycloak-service.yaml -n divoc

    # Registry
    kubectl apply -f kube-deployment-config/registry-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/registry-service.yaml -n divoc

    # Vaccination API
    kubectl apply -f kube-deployment-config/vaccination-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/vaccination-api-service.yaml -n divoc

    # Certificate Processor
    kubectl apply -f kube-deployment-config/certificate-processor-deployment.yaml -n divoc   

    # Certificate Signer
    kubectl apply -f kube-deployment-config/certificate-signer-deployment.yaml -n divoc

    # Notification Service
    kubectl apply -f kube-deployment-config/notification-service-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/notification-service-service.yaml -n divoc

    # DIGI LOCKER Service
    kubectl apply -f kube-deployment-config/digilocker-support-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/digilocker-support-api-service.yaml -n divoc

    # Certificate API
    kubectl apply -f kube-deployment-config/certificate-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/certificate-api-service.yaml -n divoc

    # PORTAL API
    kubectl apply -f kube-deployment-config/portal-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/portal-api-service.yaml -n divoc

    # Public  App
    kubectl apply -f kube-deployment-config/public-app-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/public-app-service.yaml -n divoc

    kubectl apply -f kube-deployment-config/flagr-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/flagr-service.yaml -n divoc

    

    kubectl apply -f kube-deployment-config/ingress-controller.yml

    # Ingres
    kubectl apply -f kube-deployment-config/ingres.yaml -n divoc

}

installDependencies
# installKubectl
# configureKubectl
# deployCodeOnKube
