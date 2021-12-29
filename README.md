# kubernetes-do-challenge
Kubernetes Digital Ocean Challenge

[Deploy a GitOps CI/CD implementation](https://www.digitalocean.com/community/pages/kubernetes-challenge#anchor--challenges)

## Installation:

```sh
./install.sh
```

Update the DNS records to point to the load balancer.
Install cert-manager and create Ingress for ArgoCD.

```sh
DOMAIN=my.domain EMAIL_ADDRESS=victor@my.domain ./install-cert-manager.sh
```

