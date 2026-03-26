# Oracle Cloud Infrastructure (Always Free Tier)
# Free forever - 2 ARM VMs + 2 VMs, 200GB storage

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Compartment (root)
data "oci_identity_compartment" "root" {
  compartment_id = var.tenancy_ocid
}

# VCN
resource "oci_core_vcn" "main" {
  compartment_id = data.oci_identity_compartment.root.id
  cidr_block     = "10.0.0.0/16"
  display_name   = "my-first-cicd-vcn"
  dns_label      = "myfirstcicd"
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = data.oci_identity_compartment.root.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "my-first-cicd-igw"
}

# Route Table
resource "oci_core_route_table" "main" {
  compartment_id = data.oci_identity_compartment.root.id
  vcn_id         = oci_core_vcn.main.id

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Security List
resource "oci_core_security_list" "main" {
  compartment_id = data.oci_identity_compartment.root.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "my-first-cicd-security-list"

  ingress_security_rules {
    protocol  = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 3000
      max = 3000
    }
  }

  egress_security_rules {
    protocol  = "6"
    destination = "0.0.0.0/0"
  }
}

# Subnet
resource "oci_core_subnet" "main" {
  compartment_id = data.oci_identity_compartment.root.id
  vcn_id         = oci_core_vcn.main.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "my-first-cicd-subnet"
  route_table_id = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

# SSH Key (upload to OCI)
resource "oci_core_ssh_public_key" "app_key" {
  compartment_id = data.oci_identity_compartment.root.id
  defined_tags   = {}
  display_name   = "my-first-cicd-key"
  key_content    = var.ssh_public_key
}

# Instance - Always Free ARM (Ampere A1)
resource "oci_core_instance" "app_server" {
  compartment_id = data.oci_identity_compartment.root.id
  display_name  = "my-first-cicd-server"
  shape         = "VM.Standard.A1.Flex"  # Always Free ARM

  shape_config {
    ocpus         = 1  # 1 OCPU (always free)
    memory_in_gbs = 6  # 6GB RAM (always free)
  }

  source_details {
    source_type = "image"
    image_id    = var.ubuntu_image_ocid  # Ubuntu 22.04
  }

  subnet_id        = oci_core_subnet.main.id
  ssh_public_keys  = [oci_core_ssh_public_key.app_key.key_content]

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io docker-compose git
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              EOF)
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Public IP (Always Free)
resource "oci_core_public_ip" "app_ip" {
  compartment_id = data.oci_identity_compartment.root.id
  display_name   = "my-first-cicd-public-ip"
  lifetime       = "RESERVED"
  private_ip_id  = oci_core_instance.app_server.primary_private_ip_id
}