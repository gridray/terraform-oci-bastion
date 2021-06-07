

output "bastions" {
  description = "vcn and gateways information"
  value = {
    instance_id    = module.bastion.bastion_instance_id
    ad_nam         = module.bastion.bastion_ad_name
    boot_volume_id = module.bastion.bastion_boot_volume_id
    display_name   = module.bastion.bastion_display_name
    public_ip      = module.bastion.bastion_public_ip

  }
}
