variable "region" {
  type        = string
  description = "OCI Region"
  default     = "us-ashburn-1"
}

variable "bastion_access" {
  type        = list(string)
  description = "CIDR blocks in the form of a string to which ssh access to the bastion must be restricted to. *_ANYWHERE_* is equivalent to 0.0.0.0/0 and allows ssh access from anywhere."
  default     = ["ANYWHERE"]
}

variable "image" {
  type = object({
    id = string
    version = optional(string)
  })
  description = "Image details for the bastion host, can be custom image id or leave as Autonomous"
  default = {
    id = "Autonomous"
    version = "7.9"
  }
}

variable "cidr_block" {
  type = string
  description = "IPv4 CIDR block, for bastion subnet"
}

variable "compartment_id" {
  type        = string
  description = "Compartment id where bastion should be created"
}

variable "ig_route_id" {
  type = string
  description = "the route id to the internet gateway"
}

variable "ipv6_cidr_block" {
  type = string
  description = "IPv6 CIDR block, for bastion subnet"
}

variable "notification_enabled" {
  type = bool
  description = "Whether to enable ONS notification for the bastion host."
  default = false
}

variable "notification_endpoint" {
  type        = string
  description = "The subscription notification endpoint. Email address to be notified."
  default     = null
}

variable "notification_protocol" {
  type        = string
  description = "The notification protocol used."
  default     = "EMAIL"
}

variable "notification_topic" {
  type        = string
  description = "The name of the notification topic"
  default     = "bastion"
}

variable "shape" {
  type        = object({
    shape = string
    ocpus = optional(number)
    memory = optional(number)
    boot_volume_size = optional(number)
  })
  description = "The shape of bastion instance."
  default     = {
    shape = "VM.Standard.E3.Flex"
    ocpus = 1
    memory = 4
    boot_volume_size = 50
  }
}

variable "ssh_public_key" {
  type        = string
  description = "the content of the ssh public key used to access the bastion. set this or the ssh_public_key_path"
  default     = ""
}

variable "ssh_public_key_path" {
  type        = string
  description = "path to the ssh public key used to access the bastion. set this or the ssh_public_key"
  default     = ""
}

variable "state" {
  type        = string
  description = "The target state for the instance. Could be set to RUNNING or STOPPED. (Updatable)"
  default     = "RUNNING"
}

variable "tenancy_id" {
  type = string
  description = "tenant id of the OCI"
}

variable "timezone" {
  type        = string
  description = "The preferred timezone for the bastion host."
  default     = "UTC"
}

variable "vcn_id" {
  type = string
  description = "VCN id to attach bastion node to"
}