#!/bin/sh

SRC_CODE="./src_code"

while getopts ":d:r:" opt; do
    case $opt in
        d) 
            d=$OPTARG
            ;;
        r) 
            r=$OPTARG
            ;;
        \?)
            echo "Invalid argument"
            exit 1
            ;;
    esac;
done

REGISTRY_ADDRESS=${d:-divoc}
REPO=${r:-"https://github.com/egovernments/DIVOC.git"}

echo "registry: $REGISTRY_ADDRESS"
echo "repo: $REPO"

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
    sed -i 's/divoc/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/Makefile
    sed -i 's/divoc/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/Makefile
    sed -i 's/divoc/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/certificate_signer/Makefile
    sed -i 's/divoc/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/test_certificate_signer/Makefile
    sed -i 's/divoc/'"$REGISTRY_ADDRESS"'/g' "$SRC_CODE"/backend/certificate_api/Makefile
}

buildAndPublishDivoc()
{
    make docker -C "$SRC_CODE"
    # How do we handle implementation specific versions
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