provider "azurerm" {
    subscription_id = "edb42159-c288-4e10-aea0-2f403be9a8fb"
  features {}
}

# Step 1: Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "multi-tenant-rg"
  location = "East US"
}

# Step 2: Virtual Network and Subnet (for App Service Environment)
resource "azurerm_virtual_network" "vnet" {
  name                = "multi-tenant-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "ase_subnet" {
  name                 = "ase-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "appserviceenvironment"

    service_delegation {
      name = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


# Step 3: App Service Environment (ASE) within the VNet
resource "azurerm_app_service_environment_v3" "ase" {
  name                 = "multi-tenant-ase"
  resource_group_name  = azurerm_resource_group.rg.name
  subnet_id            = azurerm_subnet.ase_subnet.id
  internal_load_balancing_mode = "None"  # "None" for public ASE, "Internal" for private ASE
}

# Step 4: App Service Plans (One per tenant)
resource "azurerm_app_service_plan" "tenant1_asp" {
  name                = "tenant1-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true  # Required for Linux

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }

  app_service_environment_id = azurerm_app_service_environment_v3.ase.id
}

resource "azurerm_app_service_plan" "tenant2_asp" {
  name                = "tenant2-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }

  app_service_environment_id = azurerm_app_service_environment_v3.ase.id
}

# Step 5: App Services (Web Apps) for each tenant
resource "azurerm_app_service" "tenant1_app" {
  name                = "tenant1-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.tenant1_asp.id

  site_config {
    linux_fx_version = "PYTHON|3.8"  # Example for Python app
  }
}

resource "azurerm_app_service" "tenant2_app" {
  name                = "tenant2-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.tenant2_asp.id

  site_config {
    linux_fx_version = "PYTHON|3.8"
  }
}

# Outputs for reference
output "tenant1_app_url" {
  value = azurerm_app_service.tenant1_app.default_site_hostname
}

output "tenant2_app_url" {
  value = azurerm_app_service.tenant2_app.default_site_hostname
}