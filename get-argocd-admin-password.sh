#!/usr/bin/bash

source ./env

${KUBECTL_BIN} -n argocd \
	get secret argocd-initial-admin-secret \
	-o jsonpath='{.data.password}' | base64 -d
