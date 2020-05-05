#!/bin/bash
echo "Running deploy.sh"
# Setup error handling
tempfiles=( )
cleanup() {
  rm -f "${tempfiles[@]}"
}
trap cleanup 0

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi

  exit "${code}"
}
trap 'error ${LINENO}' ERR

echo "Checking terraform"
if [[ ! -d ".terraform" ]]; then
    terraform init
fi

# Load the config 
echo "Loading config"
. variables.conf
resource_group_name=$(echo $base_name)rg

# Login as the service principal
echo "Getting the connection string"
#az login --service-principal -u $service_principal_id -p $service_principal_secret --tenant $azure_ad_tenant_id
az account set -s $azure_subscription_id
storage_connection_string=$(az storage account show-connection-string --name $vhd_storage_account --query connectionString --output tsv)

# Pull the most recent VHD
echo "Getting the most recent VHD"
latest_vhd=$(az storage blob list --account-name $vhd_storage_account \
                                  --container-name $vhd_storage_container \
                                  --auth-mode key \
                                  --connection-string $storage_connection_string \
                                  --prefix $vhd_path \
                                  --query '[].{name: name, create: properties.creationTime}' --output tsv \
              | grep -F '.vhd' \
              | sort -k2 -r \
              | head -n 1 \
              | cut -f1)
echo "Found $latest_vhd"

# Generate a SAS URI which expires 1 month from today
echo "Generating SAS URI"
expiry_date=$(date -d "+1 month" --iso-8601)
source_vhd=$(az storage blob generate-sas --account-name $vhd_storage_account \
                                          --container-name $vhd_storage_container \
                                          --auth-mode key \
                                          --connection-string $storage_connection_string \
                                          --name $latest_vhd \
                                          --permissions r \
                                          --expiry $expiry_date \
                                          --full-uri \
                                          --output tsv)

if [[ $(az vm list -g $resource_group_name --query '[].name' --output tsv | wc -l) != "0" ]]; then
  echo "Deleting vm $(echo $base_name)vm"
  az vm delete --name $(echo $base_name)vm \
               --resource-group $resource_group_name \
               --yes
  
  echo "Deleting VHD images"
  vhds_storage_connection_string=$(az storage account show-connection-string --name $stg_account_name --query connectionString --output tsv)
  az storage container delete --name vhds --connection-string $vhds_storage_connection_string 

  echo "Pausing for 60s. When deleting a container, the system can take a bit to fully remove the resource.."
  for i in {1..60}
    do
      echo -ne "$i.."\\r
      sleep 1s
    done
fi

terraform apply -auto-approve -var="azure_ad_tenant_id=$azure_ad_tenant_id" \
                              -var="azure_subscription_id=$azure_subscription_id" \
                              -var="base_name=$base_name" \
                              -var="location=$resource_group_location" \
                              -var="source_vhd=$source_vhd" \
                              -var="stg_account_name=$stg_account_name"

echo "Creating VM"

az vm create --name $(echo $base_name)vm \
             --resource-group $resource_group_name \
             --os-type Windows \
             --use-unmanaged-disk \
             --admin-username $admin_username \
             --admin-password $admin_password \
             --image "https://$stg_account_name.blob.core.windows.net/vhd/$base_name.vhd" \
             --nics $(echo $base_name)Nic \
             --storage-account $stg_account_name \
             --storage-container-name vhds \
             --size $vm_sku


#az logout