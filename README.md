# kubernetes-do-challenge
Kubernetes Digital Ocean Challenge

[Deploy a GitOps CI/CD implementation](https://www.digitalocean.com/community/pages/kubernetes-challenge#anchor--challenges)

## Introduction
This repository is part of Digital Ocean's 2021 Kubernetes Challenge and it is an example of a GitOps CI/CD pipeline using
ArgoCD and tekton.

This example is heavily based on the article [Kubernetes-Native Build & Release Pipelines with Tekton and ArgoCD](https://medium.com/dzerolabs/using-tekton-and-argocd-to-set-up-a-kubernetes-native-build-release-pipeline-cf4f4d9972b0).

## What the pipeline does

This CI/CD pipeline has two tasks:
1. Build the application image.
2. Deploy the application.

## Installation
Before starting the installation you should have a new Kubernetes cluster up and running, and kubectl should be configured
to have access to it.

Run the `install.sh` script, which will install Helm, Nginx Ingress controller, ArgoCD, and tekton.
```sh
./install.sh
```

Update the DNS records to point to the load balancer. You can find the IP address of your load balancer in the Digital Ocean
dashboard.
![Screenshot 2021-12-31 at 16-17-48 Load Balancers - DigitalOcean](https://user-images.githubusercontent.com/18060662/147827828-ba0a3f69-fc90-4a69-8f4f-582c7a62f27f.png)

Install cert-manager and create Ingress for ArgoCD.
```sh
DOMAIN=my.domain EMAIL_ADDRESS=victor@my.domain ./install-cert-manager.sh
```

You can now login to the ArgoCD UI at [https://argocd.MYDOMAIN](https://argocd.k8s-argocd.tk/).
![Screenshot 2021-12-31 at 16-15-05 Argo CD](https://user-images.githubusercontent.com/18060662/147827715-fe5ebf3c-d16d-4029-9e84-ef5d597e4366.png)

You can get the admin password by running:
```sh
./get-argocd-admin-password.sh
```
## Create the pipeline
To create the pipeline fork the [tekton pipeline](https://github.com/victor-timofei/tekton-example-pipeline)
and the [application repo](https://github.com/victor-timofei/tekton-pipeline-example-app).

First we'll need to create the secrets inside the `tekton-pipeline/resources/secrets` directory.
You can get the ArgoCD admin password by running the `get-argocd-admin-password.sh` script from
this repo.

For the docker password you can create an [access token](https://hub.docker.com/settings/security) if you are using docker hub.

For the github password you should use the [personal access token](https://github.com/settings/tokens).

```sh
cat << EOF > argocd_secrets.env
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=<admin_password>
EOF

cat << EOF > docker_secrets.env
username=<service_principal_id>
password=<service_principal_password>
EOF

cat << EOF > git_app_secrets.env
username=<username>
password=<personal_access_token>
EOF
```

Edit the `ARGOCD_SERVER` in `tekton-pipeline/resources/argocd-task-cm.yaml` with your ArgoCD
server address:
```yaml
  ARGOCD_SERVER: argocd.k8s-argocd.tk
```

Edit the git and docker url in `tekton-pipeline/resources/secrets.yaml`:
```yaml
    tekton.dev/git-0: https://github.com/victor-timofei/tekton-pipeline-example-app
...
    tekton.dev/docker-0: registry.hub.docker.com
```

Edit the `DOCKER_IMAGE_NAME` and `DOCKER_NAMESPACE` in `tekton-pipeline/resources/secrets.yaml`.
Since I was using docker hub, the docker namespace was my username.
```yaml
  DOCKER_IMAGE_NAME: hello-app
  DOCKER_NAMESPACE: vtimofei
```

Edit the docker registry name in the `tekton-pipeline/triggers/trigger-template.yaml`.
```yaml
    spec:
      params:
      - name: url
        # Replace <docker_registry_name> with your docker registry name (e.g. my-acr.azurecr.io)
        value: registry.hub.docker.com
```

Edit the trigger binding params in `tekton-pipeline/triggers/trigger-binding.yaml`.
These are extracted from the GitHub request webhook, depending on your git hosting service the
request schema might be different.
```yaml
spec:
  params:
  - name: git-app-repo-url
    value: $(body.repository.url)
  - name: git-app-repo-revision
    value: $(body.repository.default_branch)
```

Set your own address on the certficates and ingresses.
Edit the `tekton-pipeline/triggers/certficate.yaml` on the `tekton-example-pipeline` repo and
`kustomize/certficate.yaml` on the `tekton-pipeline-example-app` repo.
```yaml
  dnsNames:
    - k8s-argocd.tk
```

Edit the `tekton-pipeline/triggers/ingress.yaml` on the `tekton-example-pipeline` repo and
`kustomize/ingress.yaml` on the `tekton-pipeline-example-app` repo.
```yaml
  dnsNames:
    - k8s-argocd.tk
...
  tls:
  - hosts:
    - k8s-argocd.tk
```

## Add the pipeline to ArgoCD

Login to argocd via the CLI:
```sh
argocd login argocd.k8s-argocd.tk
```
You might want to add the argocd binary that was downloaded via the install script to your path.
You can do it easily with:
```sh
source env
```

Add your cluster to ArgoCD:
```sh
argocd cluster add do-fra1-k8s-challenge
```

Create the pipeline secretes:
```sh
kubectl apply -k tekton-pipeline/resources/.
```

Register your git repos with ArgoCD:
```sh
export SCM_USERNAME=<git_repo_username>
export SCM_PAT=<git_repo_personal_access_token>
argocd repo add <pipeline_repo_url> --username $SCM_USERNAME --password $SCM_PAT
argocd repo add <app_repo_url> --username $SCM_USERNAME --password $SCM_PAT
```

After this step the repositories should be visible in the ArgoCD Settings.
![Screenshot 2021-12-31 at 16-08-44 Repositories Settings - Argo CD](https://user-images.githubusercontent.com/18060662/147827489-7bd47079-8945-46d0-ab04-d2c1b4b24952.png)

Create the ArgoCD applications:
```sh
argocd app create tekton-pipeline-app --repo <pipeline_repo_url> --path tekton-pipeline --dest-server https://kubernetes.default.svc --dest-namespace tekton-argocd-example
argocd app create 2048-game-app --repo <app_repo> --path kustomize --dest-server https://kubernetes.default.svc --dest-namespace game-2048 --sync-option CreateNamespace=true
```

After this step the applications should be appear in the ArgoCD Dashboard.
![Screenshot 2021-12-31 at 16-06-56 Applications - Argo CD](https://user-images.githubusercontent.com/18060662/147827522-f9404e0e-6e83-4c29-bec1-ba5335e96d1d.png)

Sync the tekton pipeline:
```sh
argocd app sync tekton-pipeline-app --prune
```

Great, now our entire CI/CD pipeline is on Git and is managed by ArgoCD using the GitOps principles.

Register the tekton webhook with your git provider.
The webhook should be like `https://k8s-argocd.tk/tekton-argocd-example-build-webhook`.
![Screenshot 2021-12-31 at 16-19-55 victor-timofei tekton-pipeline-example-app](https://user-images.githubusercontent.com/18060662/147827863-6c2a46ed-f6d8-48bb-942c-8a965acfb0fb.png)

Now you everytime you push to your default application branch the pipeline is triggered, your
application is built and push to the container registry and finally it is deployed.

You can also see the application docker image at the [docker registry](https://hub.docker.com/repository/docker/vtimofei/hello-app).
![Screenshot 2021-12-31 at 16-22-00 Docker Hub](https://user-images.githubusercontent.com/18060662/147827980-744aa3d6-ab1c-40d9-97a0-853bf63e3ccc.png)

The application has been deployed [here](https://k8s-argocd.tk/).
![Screenshot 2021-12-31 at 16-12-40 2048](https://user-images.githubusercontent.com/18060662/147827596-9db56e3a-40ab-4a43-9e6e-a3e22fa0b71f.png)

## Resources
1. [How To Set Up an Nginx![Uploading Screenshot 2021-12-31 at 16-22-00 Docker Hub.png…]()
 Ingress on DigitalOcean Kubernetes Using Helm](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm)
2. [Installing Ambassador, ArgoCD, and Tekton on Kubernetes](https://medium.com/dzerolabs/installing-ambassador-argocd-and-tekton-on-kubernetes-540aacc983b9)
3. [Kubernetes-Native Build & Release Pipelines with Tekton and ArgoCD](https://medium.com/dzerolabs/using-tekton-and-argocd-to-set-up-a-kubernetes-native-build-release-pipeline-cf4f4d9972b0)
4. [Free SSL for Kubernetes with Cert-Manager](https://www.youtube.com/watch?v=hoLUigg4V18)
5. [Tekton Documentation](https://tekton.dev/docs/)
