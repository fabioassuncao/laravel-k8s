# Create AKS Cluster

In this phase, our focus will be on creating an auto-scalable Kubernetes cluster on Microsoft Azure AKS. Following that, we will perform the initial configurations, including deploying the Nginx Ingress Controller to route traffic to our services. Next, we will set up cert-manager to generate our SSL certificates automatically and for free using Let's Encrypt.

To streamline the process, I've chosen to create the cluster using the [Azure CLI](https://github.com/Azure/azure-cli), but feel free to configure all settings using the Azure web portal.

```bash
# Cluster Settings
# These variables will be used to create the resources. Feel free to modify them according to your needs.
REGION_NAME=brazilsouth
RESOURCE_GROUP=training-rg
SUBNET_NAME=training-aks-subnet
VNET_NAME=training-aks-vnet
AKS_CLUSTER_NAME=training-aks
K8S_VERSION=1.28
ACR_NAME=acrtrainingaks$RANDOM
CONTAINER_TAG=project-training-aks:v1.0.0
CONTAINER_REGISTRY=$ACR_NAME.azurecr.io
APP_NAMESPACE=project-training-ns
AKS_TAGS='project=training'

# Log in using Azure CLI
az login

# Create a Resource Group
az group create \
    --name $RESOURCE_GROUP \
    --location $REGION_NAME

# Creates a Virtual Network
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix 10.240.0.0/16

SUBNET_ID=$(az network vnet subnet show \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --query id -o tsv)

# Creates a AKS cluster
# For reasons unknown, there might be a failure in the cluster creation. I recommend waiting for 2 minutes and trying again. This approach worked for me! 😄
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --vm-set-type VirtualMachineScaleSets \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 5 \
    --node-count 3 \
    --node-vm-size Standard_DS2_v2 \
    --load-balancer-sku standard \
    --enable-addons monitoring \
    --location $REGION_NAME \
    --kubernetes-version $K8S_VERSION \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --service-cidr 10.2.0.0/24 \
    --dns-service-ip 10.2.0.10 \
    --generate-ssh-keys \
    --tags $AKS_TAGS \
    --network-policy calico \
    --no-wait

# Get k8s cluster credentials for local access
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME

# Get the list of nodes in the created cluster
kubectl get nodes
```

### Create ACR and associate with AKS


```bash
az acr create \
    --resource-group $RESOURCE_GROUP \
    --location $REGION_NAME \
    --name $ACR_NAME \
    --sku Standard

az aks update \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP \
    --attach-acr $ACR_NAME
```

### Build and push docker image in ACR
Optionally, you can build a Docker image of your service using the az acr command, which will handle the build and push to the Azure Container Registry. Of course, you can also use any container registry. Learn more in the [official documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).

```bash
az acr build \
    --registry $ACR_NAME \
    --image $CONTAINER_TAG .

az acr repository list \
    --name $ACR_NAME \
    --output table
```

### Deploy Ingress Controller
In this example, we will use the Ingress-Nginx Controller. Without too many details, the installation process is quite simple; just follow the recommendations from the official documentation.

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

If you want to learn more, access the [official documentation](https://kubernetes.github.io/ingress-nginx/deploy/).

### Deploy cert-manager 
In this example, we will install cert-manager, a crucial tool for certificate management in Kubernetes environments. The installation process, while straightforward, involves using `kubectl`. Simply follow the recommendations outlined in the official documentation to ensure proper configuration.

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```
If you want to learn more, access the [official documentation](https://cert-manager.io/docs/).

#### Setting up cert-manager for SSL certificate issuance with Let's Encrypt

Now that you have deployed cert-manager, it's time to configure it to issue your SSL certificates with Let's Encrypt. To do this, create the `cluster-issuer.yaml` file:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com # Don't forget to enter a valid email
    privateKeySecretRef:
      name: letsencrypt-tls
    solvers:
    - http01:
        ingress:
          class: nginx
```

After creating the `cluster-issuer.yaml` file, use the following command to apply the manifests:
```bash
kubectl apply -f cluster-issuer.yaml
```

Now you are set to work with Ingress to have it generate your SSL certificates for free.

### Deploy App

Now that you have set up your cluster with the Nginx Ingress Controller and cert-manager, you are ready to deploy your services and route traffic to them. Assuming you already have everything prepared, including all the necessary manifests like Deployment, Service, PersistentVolumeClaim, HPA, etc., use the following example `ingress.yaml` manifest to grant access to the service using a domain/subdomain:

> Don't forget to obtain the IP address of your Load Balancer. To do this, use the command `kubectl get svc` and look for the service with the name `ingress-nginx-controller`. Note that in the "EXTERNAL IP" column, you will find the IP address. With the IP of your Load Balancer in mind, simply configure your DNS settings to point your domain or subdomain to the respective IP.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host
  namespace: cartoriosmaranhao-develop
  annotations:
    spec.ingressClassName: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt"
    ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  rules:
  - host: "domain-or-subdomain-herer.com" # Don't forget to change it to a valid domain or subdomain
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: cartoriosmaranhao-develop # Don't forget to enter the correct service name here
            port:
              number: 80 # Don't forget to enter the port on which your service is available
  tls:
  - hosts:
    - "domain-or-subdomain-herer.com" # Don't forget to change it to a valid domain or subdomain
    secretName: letsencrypt-tls
```
