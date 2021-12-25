#!/usr/bin/bash

source env
source logger.sh

function install_cert_manager {
	${KUBECTL_BIN} create namespace cert-manager
	${HELM_BIN} repo add jetstack https://charts.jetstack.io
	${HELM_BIN} repo update
	${HELM_BIN} install cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--version v1.6.1 \
		--set installCRDs=true
}

function create_cluster_issuer {
	sed "s/EMAIL_ADDRESS/${EMAIL_ADDRESS}/" cluster_issuer.yaml | ${KUBECTL_BIN} apply -f -
}

log_info "Installing cert manager..."
install_cert_manager
create_cluster_issuer

log_info "Installation completed successfuly!"
