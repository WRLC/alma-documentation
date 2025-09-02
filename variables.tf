variable "location" {
  description = "Azure region"
  type        = string
}

variable "mysql_flexible_server_name" {
  description = "Existing MySQL Flexible Server name"
  type        = string
}

variable "mysql_flexible_server_rg_name" {
  description = "Resource group name of existing MySQL Flexible Server"
  type        = string
}

variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
}

variable "mysql_admin_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

variable "log_analytics_workspace_name" {
  description = "Existing Log Analytics Workspace name"
  type        = string
}

variable "log_analytics_workspace_rg_name" {
  description = "Resource group name of Existing Log Analytics Workspace"
  type        = string
}

variable "bookstack_app_key" {
  description = "BookStack application key"
  type        = string
  sensitive   = true
}

variable "bookstack_app_url" {
  description = "BookStack application URL"
  type        = string
}

