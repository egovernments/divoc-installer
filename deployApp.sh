#!/bin/sh

SRC_CODE="./src_code"

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
    cd "$SRC_CODE" || exit
    echo "Enter the docker-registry url: "
    read -r DOCKER_REGISTRY
    docker build -t "$DOCKER_REGISTRY":5000/nginx .
    docker image push "$DOCKER_REGISTRY":5000/nginx:latest
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

    # Registration API
    kubectl apply -f kube-deployment-config/registration-api-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/registration-api-deployment.yaml -n divoc

    # Flagr
    kubectl apply -f kube-deployment-config/flagr-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/flagr-service.yaml -n divoc
    
    # Public  App
    kubectl apply -f kube-deployment-config/public-app-deployment.yaml -n divoc
    kubectl apply -f kube-deployment-config/public-app-service.yml -n divoc


    
    # Ingress Controller
    kubectl apply -f kube-deployment-config/ingress-controller.yml

    # Ingres
    kubectl apply -f kube-deployment-config/ingress.yaml -n divoc

    # Worker Node IP
    kubectl get ingress -n divoc

}
cloneRepo
buildPublicApp
deployCodeOnKube