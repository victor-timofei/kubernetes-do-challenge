#!/usr/bin/bash

source ./env
source ./logger.sh

function install_cert_manager {
	${KUBECTL_BIN} create namespace cert-manager
	${HELM_BIN} repo add jetstack https://charts.jetstack.io
	${HELM_BIN} repo update
	${HELM_BIN} install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--version "v${CERT_MANAGER_VERSION}" \
		--set installCRDs=true
	${KUBECTL_BIN} apply \
		-f "https://github.com/jetstack/cert-manager/releases/download/v${CERT_MANAGER_VERSION}/cert-manager.crds.yaml"
}

function create_cluster_issuer {
	sed "s/EMAIL_ADDRESS/${EMAIL_ADDRESS}/g" ./cert-manager/cluster_issuer.yaml | ${KUBECTL_BIN} apply -f -
}

function create_certificates {
	sed "s/DOMAIN/${DOMAIN}/g" ./cert-manager/argocd_cert.yaml | ${KUBECTL_BIN} apply -f -
}

function create_argocd_ingress {
	sed "s/DOMAIN/${DOMAIN}/g" ./cert-manager/argocd_ingress.yaml | ${KUBECTL_BIN} apply -f -
}

log_info "Installing cert manager..."
install_cert_manager
create_cluster_issuer
create_certificates
create_argocd_ingress

log_info "Cert-manager installation completed successfuly!"
