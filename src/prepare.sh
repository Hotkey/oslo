PROJECT_NAME='oslo'

LOGIN_COUNT=`az account list --query 'length([])'`

if [[ $LOGIN_COUNT -eq 0 ]]
then
  az login
fi

echo 'Creating Resource Group...'

az group create --name $PROJECT_NAME-rg --location 'northeurope'

echo 'Creating Azure Container Registry...'

az acr create --name ${PROJECT_NAME}acr --resource-group $PROJECT_NAME-rg --sku Basic --admin-enabled true

echo 'Getting ACR_ID...'

ACR_ID=`az acr show --name ${PROJECT_NAME}acr --resource-group $PROJECT_NAME-rg --query 'id' --output tsv`

echo 'Creating Azure Kubernetes Service...'

az aks create --name $PROJECT_NAME-aks --resource-group $PROJECT_NAME-rg --attach-acr $ACR_ID --kubernetes-version 1.16.4 --no-ssh-key

echo 'Setting Azure Kubernetes Service Credentials...'

kubectl config unset users
kubectl config unset current-context
kubectl config unset contexts
kubectl config unset clusters

az aks get-credentials --name $PROJECT_NAME-aks --resource-group $PROJECT_NAME-rg

ACR_LOGIN_SERVER=`az acr show --name ${PROJECT_NAME}acr --resource-group $PROJECT_NAME-rg --query 'loginServer' --output tsv`

DOCKER_LOGGEDIN=`cat ~/.docker/config.json | jq '.auths' | grep "$ACR_LOGIN_SERVER" | sed 's/://' | sed 's/"//g' | sed 's/{//' | tr -d '[:space:]'`

if [ "$DOCKER_LOGGEDIN" == '' ]
then
  echo "Logging-in to Azure Container Registry through Docker CLI"
  az acr login --name ${PROJECT_NAME}acr
fi
