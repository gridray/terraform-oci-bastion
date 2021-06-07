provider "oci" {
  region = var.region
}

module "bastion" {

  source = "../../"

  context = module.this.context

  region = var.region

  # general oci parameters

  compartment_id = var.compartment_id

  tenancy_id = var.tenancy_id

  # network parameters
  ig_route_id = var.ig_rout_id

  vcn_id = var.vcn_id

  ssh_public_key_path = var.ssh_public_key_path
  cidr_block          = var.cidr_block
  ipv6_cidr_block     = ""

  shape = {
    shape = "VM.Standard.E2.1.Micro"
  }
}