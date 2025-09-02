# outputs.tf
output "bookstack_url" {
  description = "BookStack application URL"
  value       = "https://${azurerm_container_app.bookstack.latest_revision_fqdn}"
}

output "mysql_server_fqdn" {
  description = "MySQL server FQDN"
  value       = data.azurerm_mysql_flexible_server.existing.fqdn
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.bookstack.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "container_app_name" {
  description = "Container app name"
  value       = azurerm_container_app.bookstack.name
}
