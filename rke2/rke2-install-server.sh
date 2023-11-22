#!/bin/bash
set -e

RKE2_VERSION=${RKE2_VERSION:-"v1.26.10+rke2r2"}
RKE2_SERVER=${RKE2_SERVER:-}
RKE2_TOKEN=${RKE2_TOKEN:-}
TLS_SAN=${TLS_SAN:-}
CONTROL_PLANE_DEDICATED=${CONTROL_PLANE_DEDICATED:-"true"}

function banner () {
  echo "RKE2 server installer -- github.com/aramcap/rancher"
}

function pre_flight() {
  echo ""
  echo "Running preflight:"
  # if root
  if [ "$EUID" -ne 0 ]; then
    echo "- running as root: ERR"
    echo ""
    echo "Please run as root"
    exit 1
  else
    echo "- running as root: OK"
  fi
  # if selinux
  if [ "$(command -v getenforce)" ]; then
    echo "- selinux installed: OK"
    if [[ "$(getenforce)" == "Enforcing" ]]; then
      echo "- selinux permissive or disabled: ERR"
      echo ""
      echo "SELinux must be disabled or permissive"
      exit 1
    else
      echo "- selinux permissive or disabled: OK"
    fi
  else
    echo "- selinux not installed: OK"
  fi
  # if swap
  if [[ "$(swapon --show)" != "" ]]; then
    echo "- swap: ERR"
    echo ""
    echo "SWAP must be disabled: swapoff -a"
    exit 1
  else
    echo "- swap: OK"
  fi
  # if iptables
  if [ "$(command -v iptables)" ]; then
    echo "- iptables: OK"
  else
    echo "- iptables: ERR"
    echo ""
    echo "iptables is not installed"
    exit 1
  fi
  # if rke2 is installed
  if [ -e "/etc/rancher" ]; then
    echo "- host clean: ERR"
    echo ""
    echo "RKE2 is already installed. It needs clean the host (/etc/rancher)"
    exit 1
  else
    echo "- host clean: OK"
  fi
}

function install_rke2_server() {
  echo ""
  echo "Running RKE2 ${RKE2_VERSION} SERVER install:"

  # Install RKE2
  curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="${RKE2_VERSION}" sh -

  # Create a configuration for RKE2
  mkdir -p /etc/rancher/rke2
  echo "write-kubeconfig-mode: \"0600\"" >> /etc/rancher/rke2/config.yaml
  if [[ -n "${RKE2_SERVER}" ]]; then
    echo "server: https://${RKE2_SERVER}:9345" > /etc/rancher/rke2/config.yaml
  fi
  if [[ -n "${RKE2_TOKEN}" ]]; then
    echo "token: ${RKE2_TOKEN}" > /etc/rancher/rke2/config.yaml
  fi
  if [[ -n "${TLS_SAN}" ]]; then
    echo "tls-san:
  - \"${TLS_SAN}\"" > /etc/rancher/rke2/config.yaml
  fi
  if [[ "${CONTROL_PLANE_DEDICATED}" == "true" ]]; then
    echo "node-taint:
  - \"CriticalAddonsOnly=true:NoExecute\"" > /etc/rancher/rke2/config.yaml
  fi


  # start and enable service
  systemctl enable rke2-server.service
  if [[ "${?}"  -ne 0 ]]
  then
    echo "Service failed to enable"
    exit 1
  fi

  systemctl start rke2-server.service
  if [[ "${?}"  -ne 0 ]]
  then
    echo "Service failed to start"
    exit 1
  fi

  sleep 10

  # kubectl
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin'  >> ~/.bash_profile
  mkdir -p ~/.kube
  ln -s /etc/rancher/rke2/rke2.yaml ~/.kube/config
  chmod 400 ~/.kube/config

  kubectl get nodes

  echo ""
  echo "RKE2 SERVER is installed successfully"
  echo "To register other server or agents, this is the token:"
  cat /var/lib/rancher/rke2/server/node-token
}

banner
pre_flight
install_rke2_server
