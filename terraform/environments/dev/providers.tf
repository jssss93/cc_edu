terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # 로컬 백엔드 (tfstate를 로컬 파일로 관리)
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id = "42f0cf0c-5a7a-4aca-9a9e-31b236b9defa"
}
