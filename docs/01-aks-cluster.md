# Create AKS Cluster
Step-by-step guide to configuring a k8s cluster on AKS using the Azure CLI

```bash
# Cluster Settings
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

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

If you want to learn more, access the [official documentation](https://kubernetes.github.io/ingress-nginx/deploy/).

### Deploy App
...
