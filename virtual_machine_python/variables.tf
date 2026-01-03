# provider and common variables
variable "yc_zone" {
  description = "The availability zone to use for resources"
  type        = string
}

variable "yc_token" {
  description = "The OAuth token for Yandex Cloud"
  type        = string
}

variable "yc_cloud_id" {
  description = "The ID of the Yandex Cloud"
  type        = string
}

variable "yc_folder_id" {
  description = "The ID of the Yandex Cloud folder"
  type        = string
}

# network variables
variable "yc_network_name" {
  description = "The name of the VPC network to create"
  type        = string
}

# subnet variables
variable "yc_subnet_name" {
  description = "The name of the VPC subnet to create"
  type        = string
}

variable "yc_subnet_range" {
  description = "CIDR block for the subnet"
  type        = string
}

# compute disk variables
variable "yc_disk_name" {
  description = "The name of the disk to create"
  type        = string
}

variable "yc_disk_type" {
  description = "The type of disk to create"
  type        = string
}

variable "yc_image_id" {
  description = "The ID of the Yandex Cloud image to use for the VM"
  type        = string
}

# compute instance variables
variable "yc_vm_name" {
  description = "The name of the VM to create"
  type        = string
}

variable "yc_platform_id" {
  description = "The platform ID for the VM"
  type        = string
}

variable "yc_vm_cores" {
  description = "The number of CPU cores for the VM"
  type        = number
}

variable "yc_vm_memory" {
  description = "The amount of memory (GB) for the VM"
  type        = number
}

variable "yc_ssh_public_key_path" {
  description = "The path to the SSH public key file"
  type        = string
}
