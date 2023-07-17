# Resource group name is output when execution plan is applied.
resource "azurerm_resource_group" "rg_vdi" {
  name     = var.rg_name
  location = var.resource_group_location
}
#test
# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "wspace_avd_sunflow" {

  name                = var.workspace
  resource_group_name = azurerm_resource_group.rg_vdi.name
  location            = azurerm_resource_group.rg_vdi.location
  friendly_name       = "${var.prefix}-Workspace"
  description         = "${var.prefix}-Workspace"
}



# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hpool" {
  resource_group_name      = azurerm_resource_group.rg_vdi.name
  location                 = azurerm_resource_group.rg_vdi.location
  name                     = var.hostpool
  friendly_name            = var.hostpool
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  description              = "${var.prefix} Terraform HostPool"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "DepthFirst" #[BreadthFirst DepthFirst]
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hpool.id
  expiration_date = var.rfc3339
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  resource_group_name = azurerm_resource_group.rg_vdi.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hpool.id
  location            = azurerm_resource_group.rg_vdi.location
  type                = "Desktop"
  name                = "${var.prefix}-dag"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.hpool, azurerm_virtual_desktop_workspace.wspace_avd_sunflow]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
  workspace_id         = azurerm_virtual_desktop_workspace.wspace_avd_sunflow.id
} 


## RBAC PERMISSIONS

data "azuread_group" "avd_user_group"{
  display_name = "avd-pooled-users"

}
data "azurerm_role_definition" "role" { # access an existing built-in role
  name = "Desktop Virtualization User"
}
resource "azurerm_role_assignment" "role" {
  scope              = azurerm_virtual_desktop_application_group.dag.id 
  role_definition_id = data.azurerm_role_definition.role.id
  principal_id       = data.azuread_group.avd_user_group.id
}