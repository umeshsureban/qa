## Create a Resource Group for Storage
# generate a random string (consisting of four characters)
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random" {
  length  = 10
  upper   = false
  special = false
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "storage" {
  name                     = "stor${random_string.random.id}"
  location            = azurerm_resource_group.rg_vdi.location
  resource_group_name = azurerm_resource_group.rg_vdi.name
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

resource "azurerm_storage_share" "FSShare" {
  name                 = "fslogix"
  quota                = 120
  storage_account_name = azurerm_storage_account.storage.name
  depends_on           = [azurerm_storage_account.storage]
  
}

## Azure built-in roles
## https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
 data "azurerm_role_definition" "storage_role" {
  name = "Storage File Data SMB Share Contributor"
}

 data "azuread_user" "personalaccount" {
  user_principal_name = "user4@abtemp.com"
}

resource "azurerm_role_assignment" "af_role" {
  scope              = azurerm_storage_account.storage.id
  role_definition_id = data.azurerm_role_definition.storage_role.id
  principal_id       = data.azuread_user.personalaccount.id
} 
##need to assign the ad group in line  38to41