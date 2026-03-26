# Oracle Cloud Configuration
variable "tenancy_ocid" {
  description = "Tenancy OCID (from OCI Console)"
  type        = string
  default     = ""
}

variable "user_ocid" {
  description = "User OCID (from OCI Console)"
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "API Key Fingerprint"
  type        = string
  default     = ""
}

variable "private_key_path" {
  description = "Path to private API key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI Region (use ap-tokyo-1, ap-seoul-1, or ap-singapore-1 for Asia)"
  type        = string
  default     = "ap-tokyo-1"  # Closest to Philippines
}

# Ubuntu 22.04 Image OCIDs (ARM)
variable "ubuntu_image_ocid" {
  description = "Ubuntu 22.04 ARM Image OCID"
  type        = string
  default     = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaan2xj3k4a5b6c7d8e9f0g1h2i3j4k5l6m7n8o9p0q1r2s3t4u5v6"
}

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = ""  # Set your public key here
}