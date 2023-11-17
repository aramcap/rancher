#!/bin/bash

function banner () {
  echo "Longhorn deploy -- github.com/aramcap/rancher"
}

function pre_flight() {
  # if kubectl
  if [ "$(command -v kubectl)" ]; then
    echo "- kubectl: OK"
  else
    echo "- kubectl: ERR"
    echo ""
    echo "kubectl is not installed"
    exit 1
  fi
  # if jq
  if [ "$(command -v jq)" ]; then
    echo "- jq: OK"
  else
    echo "- jq: ERR"
    echo ""
    echo "jq is not installed"
    exit 1
  fi
  # if mktemp
  if [ "$(command -v mktemp)" ]; then
    echo "- mktemp: OK"
  else
    echo "- mktemp: ERR"
    echo ""
    echo "mktemp is not installed"
    exit 1
  fi
}

function check() {
  curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/scripts/environment_check.sh | bash
  if [ $? -ne 0 ]; then
    echo "
    If error was about open-iscsi, try to execute this:"
    echo "kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/deploy/prerequisite/longhorn-iscsi-installation.yaml"
    exit 1
  fi
}

function install() {
  kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/deploy/longhorn.yaml
}

banner
pre_flight
check
install