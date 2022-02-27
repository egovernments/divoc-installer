#!/bin/sh

INVENTORY_FILE="./inventory.ini"

echo "Enter the IP Address of the docker-registry: "
read -r REGISTRY_ADDRESS
echo "Enter the IP Address of the Kubernetes master node / control plane: "
read -r KUBE_MASTER
echo "Enter path to the private key to access the Kubernetes master node / control plane"
read -r KUBE_MASTER_KEY_PATH

installDependencies()
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

    if command -v helm
    then
        echo "command helm exists on system"
    else
            curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
            chmod 700 get_helm.sh
            ./get_helm.sh
    fi
}

configureKubectl()
{
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$INVENTORY_FILE" --become --become-user=root  ./ansible-cookbooks/configuration/playbook.yml --extra-vars "registry=$REGISTRY_ADDRESS:$REGISTRY_PORT"
    mkdir -p ~/.kube
    scp -i "$KUBE_MASTER_KEY_PATH" ubuntu@"$KUBE_MASTER":~/kubeadmin.conf ~/.kube/config
    sed -i 's/127.0.0.1/'"$KUBE_MASTER"'/g' ~/.kube/config

}

deployCodeOnKube()
{
    sed -i 's/REGISTRY/'"$REGISTRY_ADDRESS"'/g' kube-deployment-config/public-app-deployment.yaml
    
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
    # echo "Creating Ingress Controller, wait time is 1 minute"
    # sleep 1m
    # helm install stable/nginx-ingress --set controller.hostNetwork=true,controller.service.type="",controller.kind=DaemonSet --generate-name
    
    #Metal LB
    # kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
    # kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
    
    # Ingres
    # kubectl apply -f kube-deployment-config/ingress.yaml -n divoc

    # Worker Node IP:<NodePort>
    kubectl get svc  -n ingress-nginx

}

setupMonitoring()
{
    # install helm
    # ddefault username: admin, password: prom-operator
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add stable https://charts.helm.sh/stable
    kubectl create ns monitoring
    helm repo update
    helm install kube-prometheus  prometheus-community/kube-prometheus-stack --namespace monitoring
    kubectl patch svc kube-prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports":[{"name":"http-web", "port": 80, "protocol": "TCP", "targetPort": 3000, "nodePort": 30000}]}}'
}

echo "Starting to deploy divoc"
date
installDependencies
configureKubectl
deployCodeOnKube
setupMonitoring
echo "Installation Completed"
date