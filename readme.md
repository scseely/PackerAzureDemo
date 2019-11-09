# Requirements

Must have Azure CLI and jq installed.
* Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
* jq: https://stedolan.github.io/jq/download/

Next, login to your Azure account:
>az login
>az account set -s <subscription id>

Now, create a Service Principal to handle the login (and capture the output for this command! You can't retrieve the generated password later). Documentation for this is found at https://docs.microsoft.com/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest:

>az ad sp create-for-rbac --name ServicePrincipalName

From the output of the previous step, update demo-centos-variables.json such that the variables are appropriate for your environment. 

Finally, run packvm.sh. This will create the VM as you require. 

You can now adapt the packer file, demo-centos.json, to your requirements. 

# Updating the base image:

The following command lists the CentOS images published by OpenLogic:

>az vm image list --location centralus --publisher OpenLogic --all

Finally, when updating an existing VM offer on Azure, follow [these guidelines](https://docs.microsoft.com/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-update-existing-offer#common-update-operations).