data "oci_core_vcn" "vcn" {
  vcn_id = var.vcn_id
}

locals {
  all_protocols = "all"
  anywhere      = "0.0.0.0/0"
  ipv6_anywhere = "::/0"
  tcp_protocol  = 6
  ssh_port      = 22

  all_anywhere = length(data.oci_core_vcn.vcn.ipv6cidr_blocks) != 0 ? [local.anywhere, local.ipv6_anywhere] : [local.anywhere]

  bastion_access = length(var.bastion_access) == 1 && var.bastion_access[0] == "ANYWHERE" ? local.all_anywhere : var.bastion_access
}

resource "oci_core_security_list" "bastion" {
  count = module.this.enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${module.this.id}-bastion"
  freeform_tags  = module.this.tags

  dynamic "egress_security_rules" {
    for_each = local.all_anywhere
    content {
      protocol    = local.all_protocols
      destination = egress_security_rules.value
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.bastion_access
    content {
      # allow ssh
      protocol = local.tcp_protocol
      source   = ingress_security_rules.value

      tcp_options {
        min = local.ssh_port
        max = local.ssh_port
      }
    }
  }
  vcn_id = var.vcn_id
}


resource "oci_core_subnet" "bastion" {
  count = module.this.enabled ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${module.this.id}-bastion"
  freeform_tags  = module.this.tags

  ipv6cidr_block             = var.ipv6_cidr_block
  cidr_block                 = var.cidr_block
  dns_label                  = module.this.name== "" ? "bastion": module.this.name
  prohibit_public_ip_on_vnic = false
  route_table_id             = var.ig_route_id
  security_list_ids          = [oci_core_security_list.bastion[0].id]
  vcn_id                     = var.vcn_id
}

data "oci_identity_availability_domains" "ad_list" {
  compartment_id = var.compartment_id
}

data "template_file" "ad_names" {
  count    = length(data.oci_identity_availability_domains.ad_list.availability_domains)
  template = lookup(data.oci_identity_availability_domains.ad_list.availability_domains[count.index], "name")
}

locals {
  ad_names = data.template_file.ad_names.*.rendered
  bastion_ad_name = local.ad_names[0]
}


# OCI notifications
resource "oci_ons_notification_topic" "bastion_notification" {
  count          = module.this.enabled && var.notification_enabled ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${module.this.id}-${var.notification_topic}"
  description    = "Terraformed: Bastion Notification topic"
  freeform_tags = module.this.tags
}

resource "oci_ons_subscription" "bastion_notification" {
  count = module.this.enabled && var.notification_enabled ? 1 : 0

  compartment_id = var.compartment_id
  endpoint       = var.notification_endpoint
  protocol       = var.notification_protocol
  topic_id       = oci_ons_notification_topic.bastion_notification[0].topic_id
}

resource "oci_identity_dynamic_group" "bastion_notification" {
  count = module.this.enabled && var.notification_enabled ? 1 : 0

  compartment_id = var.compartment_id

  name           = "${module.this.id}-bastion-notification"
  description    = "dynamic group to allow bastion to send notifications to ONS"
  freeform_tags = module.this.tags

  matching_rule  = "ALL {instance.id = '${join(",", oci_core_instance.bastion.*.id)}'}"

  provider = oci.home
}

resource "oci_identity_policy" "bastion_notification" {
  count = module.this.enabled && var.notification_enabled ? 1 : 0

  name           = "${module.this.id}-bastion-notification"
  description    = "policy to allow bastion host to publish messages to ONS"
  freeform_tags = module.this.tags

  compartment_id = var.compartment_id
  depends_on     = [oci_core_instance.bastion]
  statements     = ["Allow dynamic-group ${oci_identity_dynamic_group.bastion_notification[0].name} to use ons-topic in compartment id ${var.compartment_id} where request.permission='ONS_TOPIC_PUBLISH'"]

  provider = oci.home
}

locals {
  shape = var.shape.shape
  is_flex_shape = length(regexall("Flex", local.shape)) > 0
}

data "oci_core_images" "autonomous_images" {
  compartment_id           = var.compartment_id

  operating_system         = "Oracle Autonomous Linux"
  operating_system_version = lookup(var.image, "version", "7.9")
  shape                    = local.shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  is_autonomous_image = var.image.id == "Autonomous"
  bastion_image_id = local.is_autonomous_image ? data.oci_core_images.autonomous_images.images.0.id : var.image.id
}

# cloud init for bastion
data "template_file" "autonomous_template" {
  count = (module.this.enabled && local.is_autonomous_image) ? 1 : 0

  template = file("${path.module}/scripts/notification.template.sh")

  vars = {
    notification_enabled = var.notification_enabled
    topic_id             = var.notification_enabled ? oci_ons_notification_topic.bastion_notification[0].topic_id : "null"
  }
}

data "template_file" "autonomous_cloud_init_file" {
  count = (module.this.enabled && local.is_autonomous_image) ? 1 : 0

  template = file("${path.module}/cloudinit/autonomous.template.yaml")

  vars = {
    notification_sh_content = base64gzip(data.template_file.autonomous_template[0].rendered)
    timezone                = var.timezone
  }
}

data "template_cloudinit_config" "bastion" {
  count = module.this.enabled? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    filename     = "bastion.yaml"
    content_type = "text/cloud-config"
    content      = data.template_file.autonomous_cloud_init_file[0].rendered
  }

}

resource "oci_core_instance" "bastion" {
  count = module.this.enabled ? 1 : 0

  compartment_id      = var.compartment_id
  display_name = "${module.this.id}-bastion"
  freeform_tags       = module.this.tags

  availability_domain = local.bastion_ad_name

  create_vnic_details {
    assign_public_ip = true
    display_name     = "${module.this.name}-bastion-vnic"
    hostname_label   = "bastion"
    subnet_id        = oci_core_subnet.bastion[0].id
  }

  launch_options {
    boot_volume_type = "PARAVIRTUALIZED"
    network_type     = "PARAVIRTUALIZED"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key != "" ? var.ssh_public_key : file(var.ssh_public_key_path)
    user_data           = data.template_cloudinit_config.bastion[0].rendered
  }

  shape = local.shape

  dynamic "shape_config" {
    for_each = local.is_flex_shape ? [1] : []
    content {
      ocpus         = max(1, lookup(var.shape, "ocpus", 1))
      memory_in_gbs = (lookup(var.shape, "memory", 4) / lookup(var.shape, "ocpus", 1)) > 64 ? (lookup(var.shape, "ocpus", 1) * 4) : lookup(var.shape, "memory", 4)
    }
  }

  source_details {
    boot_volume_size_in_gbs = lookup(var.shape, "boot_volume_size", 50)
    source_type             = "image"
    source_id               = local.bastion_image_id
  }

  state = var.state

  timeouts {
    create = "60m"
  }

  # prevent the bastion from destroying and recreating itself if the image ocid changes
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

}

data "oci_core_vnic_attachments" "bastion_vnics_attachments" {
  count  = module.this.enabled? 1: 0

  availability_domain = local.bastion_ad_name
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.bastion[0].id

  depends_on          = [oci_core_instance.bastion]
}

# Gets the OCID of the first (default) VNIC on the bastion instance
data "oci_core_vnic" "bastion_vnic" {
  count  = module.this.enabled? 1: 0

  vnic_id    = lookup(data.oci_core_vnic_attachments.bastion_vnics_attachments[0].vnic_attachments[0], "vnic_id")

  depends_on = [oci_core_instance.bastion]
}
