
variable "azure_ad_tenant_id" {
    type    = string
    default = ""
}

variable "azure_subscription_id" {
    type    = string
    default = ""
}

variable "service_principal_client_secret" {
    type    = string
    default = ""
}

variable "service_principal_client_id" {
    type    = string
    default = ""
}

variable "location" {
    type    = string
    default = "centralus"
}

variable "base_name" {
    type    = string
    default = "dummybase"
}

variable "source_vhd" {
    type    = string
    default = ""
}

variable "stg_account_name" {
    type    = string
    default = ""
}