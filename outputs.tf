

output "bastion_instance_id" {
  value = join(",", oci_core_instance.bastion.*.id)
}

output "bastion_ad_name" {
  value = local.bastion_ad_name
}

output "bastion_boot_volume_id" {
  value = join(",", oci_core_instance.bastion.*.boot_volume_id)
}

output "bastion_display_name" {
  value = join(",", oci_core_instance.bastion.*.display_name)
}

output "bastion_public_ip" {
  value = join(",", data.oci_core_vnic.bastion_vnic.*.public_ip_address)
}