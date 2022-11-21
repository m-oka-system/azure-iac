################################
# User Assigned Managed ID
################################
resource "azurerm_user_assigned_identity" "reader" {
  name                = "${var.prefix}-${var.env}-reader-id"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "reader" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${azurerm_resource_group.rg.name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.reader.principal_id
}
