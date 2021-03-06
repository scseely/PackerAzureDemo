#!/bin/bash

var_file='demo-redhat-variables-scott.json'
packer_file='demo-redhat.json'

function capture_var() {
    val=$(cat $var_file | jq .$1 | tail -c +2 | head -c -2)
    echo $val
}

service_principal_client_id=$(capture_var service_principal_client_id)
service_principal_client_secret=$(capture_var service_principal_client_secret)
azure_ad_tenant_id=$(capture_var azure_ad_tenant_id)
azure_subscription_id=$(capture_var azure_subscription_id)
resource_group_name=$(capture_var resource_group_name)
resource_group_location=$(capture_var resource_group_location)
azure_storage_account=$(capture_var azure_storage_account)
echo "Logging in"
az login --service-principal -u $service_principal_client_id -p $service_principal_client_secret --tenant $azure_ad_tenant_id

# Check if the needed resource group has been created
echo "Making sure that the resource group $resource_group_name exists"

if [[ "false" == $(az group exists -n $resource_group_name) ]]; then
    echo "Creating resource group"
    az group create -l $resource_group_location -n $resource_group_name
fi

if [[ "true" == $(az storage account check-name --name $azure_storage_account --query nameAvailable) ]]; then
    echo "Creating storage account"
    az storage account create \
        -n $azure_storage_account \
        -g $resource_group_name \
        -l $resource_group_location \
        --sku Standard_LRS
fi

echo "Building packer image"
packer build -var-file=$var_file -force $packer_file

az logout
