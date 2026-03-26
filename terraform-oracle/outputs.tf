# Oracle Cloud Outputs
output "instance_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_public_ip.app_ip.ip_address
}

output "instance_name" {
  description = "Instance name"
  value       = oci_core_instance.app_server.display_name
}

output "instance_shape" {
  description = "Instance shape"
  value       = oci_core_instance.app_server.shape
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = oci_core_subnet.main.id
}

output "ssh_connection" {
  description = "SSH command to connect"
  value       = "ssh -i <your-private-key> ubuntu@${oci_core_public_ip.app_ip.ip_address}"
}