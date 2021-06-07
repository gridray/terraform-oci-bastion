terraform {
  required_version = ">= 0.14.0"

  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.29.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
  }
}
