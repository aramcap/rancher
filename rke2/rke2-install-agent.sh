#!/bin/bash
set -e

RKE2_VERSION=${RKE2_VERSION:-"v1.26.8+rke2r1"}
RKE2_SERVER=${RKE2_SERVER:-}
RKE2_TOKEN=${RKE2_TOKEN:-}

function banner () {
  echo "RKE2 agent installer -- github.com/aramcap/rancher"
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

function get_params() {
  if [[ -z "${RKE2_SERVER}" ]]; then
    read -p "RKE2_SERVER: " RKE2_SERVER
  fi
  if [[ -z "${RKE2_TOKEN}" ]]; then
    read -p "RKE2_TOKEN: " RKE2_TOKEN
  fi
}

function install_rke2_agent() {
  echo ""
  echo "Running RKE2 ${RKE2_VERSION} AGENT install:"

  # Install RKE2
  curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="${RKE2_VERSION}" INSTALL_RKE2_TYPE="agent" sh -

  # Create a configuration for RKE2
  mkdir -p /etc/rancher/rke2
  echo "server: https://${RKE2_SERVER}:9345
token: ${RKE2_TOKEN}" >> /etc/rancher/rke2/config.yaml
!

  # start and enable service
  systemctl enable rke2-agent.service
  if [[ "${?}"  -ne 0 ]]
  then
    echo "Service failed to enable"
    exit 1
  fi

  systemctl start rke2-agent.service
  if [[ "${?}"  -ne 0 ]]
  then
    echo "Service failed to start"
    exit 1
  fi

  echo ""
  echo "RKE2 AGENT is installed successfully"
  echo "Run on control-plane: kubectl label node $(hostname) node-role.kubernetes.io/worker=worker"
}

banner
pre_flight
get_params
install_rke2_agent
