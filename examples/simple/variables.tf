variable "region" {
  type        = string
  description = "OCI region"
}

variable "tenancy_id" {
  type = string
}
variable "compartment_id" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "ig_rout_id" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}