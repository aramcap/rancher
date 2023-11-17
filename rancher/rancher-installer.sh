#!/bin/bash
RANCHER_VERSION="2.7.6"
FQDN=""
REPLICAS=1
ADMINPASSWORD=rancherpassword

function banner () {
  echo "Rancher installer -- github.com/aramcap"
}

function install_rancher(){
  echo ""
  echo "Running Rancher ${RANCHER_VERSION} install:"

  # add helm
  curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

  # helm charts
  helm repo add jetstack https://charts.jetstack.io
  helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
  
  # install cert manager
  helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.11.0 --set installCRDs=true --create-namespace
  # wait the cert-manager get installed
  sleep 10
  kubectl wait deployment -n cert-manager cert-manager --for condition=Available=True --timeout=120s
  kubectl wait deployment -n cert-manager cert-manager-cainjector --for condition=Available=True --timeout=120s
  kubectl wait deployment -n cert-manager cert-manager-webhook --for condition=Available=True --timeout=120s

  # install rancher
  helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=${FQDN} --set replicas=${REPLICAS} --version ${RANCHER_VERSION} --set bootstrapPassword=${ADMINPASSWORD} --create-namespace

  # wait all rancher pods get spawn
  sleep 10
  kubectl wait deployment -n cattle-system rancher --for condition=Available=True --timeout=240s

  echo ""
  echo "Rancher is installed successfully"
}

banner

echo "Rancher FQDN: "
read FQDN
echo "Rancher replicas: "
read REPLICAS

install_rancher
