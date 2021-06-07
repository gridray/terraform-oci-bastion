provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = [for i in data.oci_identity_region_subscriptions.this.region_subscriptions : i.region_name if i.is_home_region == true][0]
}

data "oci_identity_region_subscriptions" "this" {
  tenancy_id = var.tenancy_id
}
