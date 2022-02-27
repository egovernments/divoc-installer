#!/bin/sh

SRC_CODE="./src_code"

echo "Enter the IP Address with port of the docker-registry: "
read -r REGISTRY_ADDRESS
echo "Enter the repository containing the source code: "
read -r REPO

installDependencies()
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
}

cloneRepo()
{
    echo "Cloning from $REPO into local directory $SRC_CODE"
    git clone -q "$REPO" "$SRC_CODE"
    echo "Source Code cloned successfully"
}

replaceDockerRegistryWithPrivateRegistry()
{
    sed -i 's/dockerhub/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/Makefile
    sed -i 's/dockerhub/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/Makefile
    sed -i 's/dockerhub/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/certificate_signer/Makefile
    sed -i 's/dockerhub/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/test_certificate_signer/Makefile
    sed -i 's/dockerhub/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/certificate_api/Makefile
}

buildAndPublishDivoc()
{
    make docker -C "$SRC_CODE"
    make publish -C "$SRC_CODE"
    echo "Deleting $SRC_CODE"
    rm -rf "$SRC_CODE"
}

echo "Starting build"
date
installDependencies
cloneRepo
replaceDockerRegistryWithPrivateRegistry
buildAndPublishDivoc
echo "build completed"
date