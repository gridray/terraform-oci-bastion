terraform {
  required_version = ">= 0.14.0"
  experiments = [module_variable_optional_attrs]

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.29.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
}
