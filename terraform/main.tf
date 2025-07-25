# Directory: terraform/main.tf

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "archive" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
}

resource "azurerm_storage_container" "billing_archive" {
  name                  = "billing-archive"
  storage_account_name  = azurerm_storage_account.archive.name
  container_access_type = "private"
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmos_account_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmos_database_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = var.cosmos_container_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name

  partition_key_path = "/partitionKey"
  throughput          = 400
}

resource "azurerm_storage_account_network_rules" "rules" {
  storage_account_id = azurerm_storage_account.archive.id
  default_action     = "Allow"
}

resource "azurerm_application_insights" "ai" {
  name                = "archive-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

resource "azurerm_function_app" "archive_func" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.archive.name
  storage_account_access_key = azurerm_storage_account.archive.primary_access_key
  app_settings = {
    "AzureWebJobsStorage"        = azurerm_storage_account.archive.primary_connection_string
    "COSMOS_ENDPOINT"           = azurerm_cosmosdb_account.cosmos.endpoint
    "COSMOS_KEY"                = azurerm_cosmosdb_account.cosmos.primary_key
    "COSMOS_DB"                 = var.cosmos_database_name
    "COSMOS_CONTAINER"          = var.cosmos_container_name
    "BLOB_CONN"                 = azurerm_storage_account.archive.primary_connection_string
    "BLOB_CONTAINER"            = azurerm_storage_container.billing_archive.name
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.ai.instrumentation_key
  }
  site_config {
    application_insights_key = azurerm_application_insights.ai.instrumentation_key
    always_on                = true
  }
  os_type = "linux"
  version = "~4"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "archive-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
