# Configure the Microsoft Azure Provider
provider "azurerm" {
    version         = "=2.0.0"
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_ad_tenant_id   
    client_id       = var.service_principal_client_id
    client_secret   = var.service_principal_client_secret
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "resourcegroup" {
    name     = "${var.base_name}rg"
    location = var.location

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "network" {
    name                = "${var.base_name}Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

# Create subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${var.base_name}Subnet"
    resource_group_name  = azurerm_resource_group.resourcegroup.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "publicip" {
    name                         = "${var.base_name}IP"
    location                     = azurerm_resource_group.resourcegroup.location
    resource_group_name          = azurerm_resource_group.resourcegroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.base_name}Nsg"
    location            = azurerm_resource_group.resourcegroup.location
    resource_group_name = azurerm_resource_group.resourcegroup.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
    name                      = "${var.base_name}Nic"
    location                  = azurerm_resource_group.resourcegroup.location
    resource_group_name       = azurerm_resource_group.resourcegroup.name
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
        name                          = "${var.base_name}NicConfiguration"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "diag" {
    name                        = var.stg_account_name
    resource_group_name         = azurerm_resource_group.resourcegroup.name
    location                    = azurerm_resource_group.resourcegroup.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
    account_kind                = "StorageV2"

    tags = {
        environment = "${var.base_name} VM Verification"
    }
}

resource "azurerm_storage_container" "vhd" {
  name                  = "vhd"
  storage_account_name  = azurerm_storage_account.diag.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "vhds" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.diag.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "vhd" {
  name                   = "${var.base_name}.vhd"
  storage_account_name   = azurerm_storage_account.diag.name
  storage_container_name = azurerm_storage_container.vhd.name
  type                   = "Page"
  source_uri             = var.source_vhd
}