#!/bin/sh

INVENTORY_FILE="./inventory.ini"
SRC_CODE="./src_code"

echo "Enter the IP Address of the docker-registry: "
read -r REGISTRY
echo "Enter the IP Address of the Kubernetes master node / control plane: "
read -r KUBE_MASTER
echo "Enter path to the private key to access the Kubernetes master node / control plane"
read -r KUBE_MASTER_KEY_PATH
echo "Enter the repository containing the source code: "
read -r REPO


configureKubectl()
{
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/configuration/playbook.yml --extra-vars "registry=$REGISTRY"
    mkdir -p ~/.kube
    scp -i "$KUBE_MASTER_KEY_PATH" ubuntu@"$KUBE_MASTER":~/kubeadmin.conf ~/.kube/config
    sed -i 's/127.0.0.1/'"$KUBE_MASTER"'/g' ~/.kube/config

}

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
    echo "Cloning from $REPO into local directory $SRC_CODE"
    git clone -q "$REPO" "$SRC_CODE"
    echo "Source Code cloned successfully"
}

buildPublicApp()
{
        if command -v make
    then 
        echo "command make exists on system"
    else   
        echo "make could not be found"
        echo "installing make"
        apt -qq -y update
        apt -qq -y install make
    fi

    if command -v docker
    then 
        echo "command docker exists on system"
    else   
        echo "docker could not be found"
        echo "installing docker"
        apt -qq -y update
        apt -qq -y install docker.io
    fi

    docker build -t "$REGISTRY":5000/nginx "$SRC_CODE"
    docker image push "$REGISTRY":5000/nginx:latest
    echo "Deleting $SRC_CODE"
    rm -rf "$SRC_CODE"

}

deployCodeOnKube()
{
    sed -i 's/REGISTRY/'"$REGISTRY"'/g' kube-deployment-config/public-app-deployment.yaml
    
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

    # Registration API
    kubectl apply -f kube-deployment-config/registration-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/registration-api-service.yaml -n divoc

    # Flagr
    kubectl apply -f kube-deployment-config/flagr-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/flagr-service.yaml -n divoc
    
    # Public  App
    kubectl apply -f kube-deployment-config/public-app-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/public-app-service.yml -n divoc
    
    # Ingress Controller
    kubectl apply -f kube-deployment-config/ingress-controller.yml
    echo "Creating Ingress Controller, wait time is 1 minute"
    sleep 1m
    

    # Ingres
    kubectl apply -f kube-deployment-config/ingress.yaml -n divoc

    # Worker Node IP:<NodePort>
    kubectl get svc  -n ingress-nginx

}

setupMonitoring()
{
    kubectl create -f kube-deployment-config/monitoring/prometheus/manifests/setup/
    echo "Waiting for pods to come online, sleeping for  2 minutes"
    sleep 2m
    kubectl create -f kube-deployment-config/monitoring/prometheus/manifests/
    echo "Waiting for pods to come online, sleeping for  2 minutes"
    sleep 2m
    kubectl apply -f kube-deployment-config/ingress-monitoring.yaml
}

configureKubectl
cloneRepo
buildPublicApp
deployCodeOnKube
# setupMonitoring