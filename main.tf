# Existing database server
data "azurerm_mysql_flexible_server" "existing" {
  name                = var.mysql_flexible_server_name
  resource_group_name = var.mysql_flexible_server_rg_name
}

# Existing log analytics workspace
data "azurerm_log_analytics_workspace" "existing" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_rg_name
}

# Local vars
locals {
  resource_name = "bookstack"
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_name}-rg"
  location = var.location
}

# Storage Account for file share
resource "azurerm_storage_account" "bookstack" {
  name                     = "${local.resource_name}${random_string.suffix.result}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# File Share for BookStack config/storage
resource "azurerm_storage_share" "bookstack_config" {
  name               = "bookstack-config"
  storage_account_id = azurerm_storage_account.bookstack.id
  quota              = 100 # GB
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "bookstack" {
  name                = "bookstack"
  resource_group_name = data.azurerm_mysql_flexible_server.existing.resource_group_name
  server_name         = data.azurerm_mysql_flexible_server.existing.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Random MySQL user password
resource "random_password" "database" {
  length  = 24
  special = false
}

# MySQL user
resource "mysql_user" "database" {
  user               = "${local.resource_name}_user"
  host               = "%"
  plaintext_password = random_password.database.result
}

# MySQL grant
resource "mysql_grant" "database" {
  user       = mysql_user.database.user
  host       = mysql_user.database.host
  database   = azurerm_mysql_flexible_database.bookstack.name
  privileges = ["ALL PRIVILEGES"]
}

# Container Apps Environment
resource "azurerm_container_app_environment" "bookstack" {
  name                       = "cae-bookstack-${local.resource_name}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.existing.id
}

# Container Apps Environment Storage (for file share)
resource "azurerm_container_app_environment_storage" "bookstack_config" {
  name                         = "bookstack-config-storage"
  container_app_environment_id = azurerm_container_app_environment.bookstack.id
  account_name                 = azurerm_storage_account.bookstack.name
  share_name                   = azurerm_storage_share.bookstack_config.name
  access_key                   = azurerm_storage_account.bookstack.primary_access_key
  access_mode                  = "ReadWrite"
}

# Container App
resource "azurerm_container_app" "bookstack" {
  name                         = "ca-bookstack-${local.resource_name}"
  container_app_environment_id = azurerm_container_app_environment.bookstack.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 2

    volume {
      name         = "bookstack-config"
      storage_name = azurerm_container_app_environment_storage.bookstack_config.name
      storage_type = "AzureFile"
    }

    container {
      name   = "bookstack"
      image  = "lscr.io/linuxserver/bookstack:latest"
      cpu    = 1.0
      memory = "2Gi"

      volume_mounts {
        name = "bookstack-config"
        path = "/config"
      }

      env {
        name  = "PUID"
        value = "1000"
      }

      env {
        name  = "PGID"
        value = "1000"
      }

      env {
        name  = "TZ"
        value = "UTC"
      }

      env {
        name  = "APP_URL"
        value = var.bookstack_app_url
      }

      env {
        name        = "APP_KEY"
        secret_name = "app-key"
      }

      env {
        name  = "DB_HOST"
        value = data.azurerm_mysql_flexible_server.existing.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "3306"
      }

      env {
        name  = "DB_USERNAME"
        value = mysql_user.database.user
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "DB_DATABASE"
        value = azurerm_mysql_flexible_database.bookstack.name
      }

      env {
        name  = "QUEUE_CONNECTION"
        value = "database"
      }

      # Optional: Add session and cache configuration for better performance
      env {
        name  = "SESSION_DRIVER"
        value = "database"
      }

      env {
        name  = "CACHE_DRIVER"
        value = "database"
      }
    }
  }

  secret {
    name  = "app-key"
    value = var.bookstack_app_key
  }

  secret {
    name  = "db-password"
    value = random_password.database.result
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    azurerm_container_app_environment_storage.bookstack_config
  ]
}
