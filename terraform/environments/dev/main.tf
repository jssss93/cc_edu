# dev 환경 - Hub-Spoke 아키텍처

locals {
  # 공통 태그 (의도적 포맷 오류)
  common_tags = {
    environment = var.environment
    owner       = var.owner
    project     = var.project
  }

  # 리소스 그룹 이름
  hub_rg_name   = "rg-${var.project}-hub-${var.environment}-${var.location}"
  spoke_rg_name = "rg-${var.project}-spoke-${var.environment}-${var.location}"
}

# Hub 리소스 그룹
resource "azurerm_resource_group" "hub" {
  name     = local.hub_rg_name
  location = var.location
  tags     = local.common_tags
}

# Spoke 리소스 그룹
resource "azurerm_resource_group" "spoke" {
  name     = local.spoke_rg_name
  location = var.location
  tags     = local.common_tags
}

# Hub VNet 모듈
module "hub_vnet" {
  source = "../../modules/hub-vnet"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  vnet_name           = "vnet-hub-${var.environment}-${var.location}"
  vnet_address_space  = var.hub_vnet_address_space
  tags                = local.common_tags
}

# Spoke VNet 모듈
module "spoke_vnet" {
  source = "../../modules/spoke-vnet"

  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  vnet_name           = "vnet-spoke-${var.environment}-${var.location}"
  vnet_address_space  = var.spoke_vnet_address_space
  tags                = local.common_tags
}

# Function App VNet integration용 전용 서브넷
resource "azurerm_subnet" "function" {
  name                 = "snet-func"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = module.spoke_vnet.vnet_name
  address_prefixes     = ["10.1.2.0/24"]

  # Function App VNet integration 위임
  delegation {
    name = "func-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  # Storage 서비스 엔드포인트 (Storage Account 접근용)
  service_endpoints = ["Microsoft.Storage"]

  depends_on = [module.spoke_vnet]
}

# Function App용 Storage Account (EP1 Plan + VNet integration)
resource "azurerm_storage_account" "function" {
  # checkov:skip=CKV2_AZURE_1: dev 환경 - CMK 미사용
  # checkov:skip=CKV2_AZURE_18: dev 환경 - CMK 미사용
  # checkov:skip=CKV2_AZURE_33: dev 환경 - private endpoint 미사용
  # checkov:skip=CKV_AZURE_206: dev 환경 - replication 최소화
  # checkov:skip=CKV_AZURE_33: Function App 전용 스토리지 - Queue 서비스 미사용
  name                            = "stfunc${var.project}${var.environment}"
  public_network_access_enabled   = false # VNet 서비스 엔드포인트로만 접근
  resource_group_name             = azurerm_resource_group.spoke.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Function App 서브넷 + Terraform 러너 IP 허용 (구독 정책 준수, 파일 공유 사전 생성용)
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.function.id]
    ip_rules                   = var.runner_ip != "" ? [var.runner_ip] : []
  }

  tags = local.common_tags
}

# Function App용 파일 공유 사전 생성 (WEBSITE_CONTENTOVERVNET 필수 요건)
resource "azurerm_storage_share" "function" {
  name               = "func-${var.project}-${var.environment}-content"
  storage_account_id = azurerm_storage_account.function.id
  quota              = 5

  depends_on = [azurerm_storage_account.function]
}

# Function App Service Plan (Elastic Premium EP1 - VNet integration 지원)
resource "azurerm_service_plan" "function" {
  # checkov:skip=CKV_AZURE_225: dev 환경 - zone redundancy 미사용
  # checkov:skip=CKV_AZURE_212: dev 환경 - 단일 인스턴스 운영
  name                = "asp-func-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "EP1" # Elastic Premium (VNet integration 지원, 최소 Premium)

  tags = local.common_tags
}

# Linux Function App
resource "azurerm_linux_function_app" "main" {
  # checkov:skip=CKV_AZURE_221: dev 환경 - 외부 테스트 접근 허용
  name                       = "func-${var.project}-${var.environment}"
  resource_group_name        = azurerm_resource_group.spoke.name
  location                   = var.location
  storage_account_name       = azurerm_storage_account.function.name
  storage_account_access_key = azurerm_storage_account.function.primary_access_key
  service_plan_id            = azurerm_service_plan.function.id
  https_only                 = true
  virtual_network_subnet_id  = azurerm_subnet.function.id # VNet integration

  # VNet을 통해 스토리지 접근 강제 (네트워크 제한 Storage 필수 설정)
  app_settings = {
    "WEBSITE_CONTENTOVERVNET"                  = "1"
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.function.name
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = azurerm_storage_account.function.primary_connection_string
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  tags = local.common_tags
}

# VNet 피어링 모듈 (Hub VNet 생성 이후 설정)
module "vnet_peering" {
  source = "../../modules/vnet-peering"

  hub_vnet_name             = module.hub_vnet.vnet_name
  hub_vnet_id               = module.hub_vnet.vnet_id
  hub_resource_group_name   = azurerm_resource_group.hub.name
  spoke_vnet_name           = module.spoke_vnet.vnet_name
  spoke_vnet_id             = module.spoke_vnet.vnet_id
  spoke_resource_group_name = azurerm_resource_group.spoke.name

  depends_on = [module.hub_vnet, module.spoke_vnet]
}

