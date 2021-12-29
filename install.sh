#!/usr/bin/bash

source ./env
source ./logger.sh

function install_helm {
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
		| USE_SUDO="false" HELM_INSTALL_DIR="${INSTALL_DIR}" bash
}

function install_nginx_ingress_controller {
	${HELM_BIN} repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	${HELM_BIN} repo update
	${HELM_BIN} install nginx-ingress ingress-nginx/ingress-nginx \
		--set controller.publishService.enabled=true
}

function install_argocd_full {
	${KUBECTL_BIN} create namespace argocd
	${KUBECTL_BIN} apply \
		-n argocd \
		-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

	curl -sSL -o "${ARGOCD_BIN}" https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	chmod +x "${ARGOCD_BIN}"

}

function install_tekton {
	${KUBECTL_BIN} apply \
		-f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
}

mkdir -pv "${INSTALL_DIR}"

log_info "Installing Helm..."
install_helm

log_info "Installing NGINX ingress controller..."
install_nginx_ingress_controller

log_info "Installing Argo CD..."
install_argocd_full

log_info "Installing Tekton..."
install_tekton

log_info "Installation completed successfuly!"
