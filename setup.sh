#!/usr/bin/env bash

# allow checking for installed commands
command_exists() {
  command -v "$1" 1>/dev/null 2>&1
  return $?
}

################################################################################
# Logging                                                                      #
################################################################################
function log() {
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  ORANGE='\033[0;33m'
  NC='\033[0m'
  LEVEL=$1
  MSG=$2
  case $LEVEL in
  "INFO") HEADER_COLOR=$GREEN MSG_COLOR=$NC ;;
  "WARN") HEADER_COLOR=$ORANGE MSG_COLOR=$NC ;;
  "ERROR") HEADER_COLOR=$RED MSG_COLOR=$NC ;;
  esac
  printf "${HEADER_COLOR}[%-5.5s]${NC} ${MSG_COLOR}%b${NC}\n" "${LEVEL}" "${MSG}"
}

function info() {
  log "INFO" "$1"
}

function warn() {
  log "WARN" "$1"
}

function error() {
  log "ERROR" "$1" && exit 1
}

log_and_run() {
  info "$(date +'%H:%M:%S') - Running: $*"
  if [ $# -eq 1 ]; then
    eval "$1"
  else
    "$@"
  fi
}

info "this script will install all the random tools you need for infrastructure development" 

# confirm if required tools are installed
# kubectl
# brew

if command_exists brew; then 
  info "brew is installed"
else
  warn "brew is not installed" 
  error "go to brew.sh to install"
fi

if command_exists kubectl; then 
  info "kubectl is installed"
else
  warn "kubectl is not installed" 
  error "go to https://kubernetes.io/docs/tasks/tools/#kubectl to install"
fi
