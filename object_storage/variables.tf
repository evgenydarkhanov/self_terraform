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

# service account variables
variable "yc_sa_name" {
  description = "The name of the service account to create"
  type        = string
}

# bucket variables
variable "yc_bucket_name" {
  description = "The name of the storage bucket to create"
  type        = string
}

variable "yc_bucket_size" {
  description = "The size of the storage bucket to create"
  type        = number
}

variable "yc_default_storage_class" {
  description = "The class of the storage bucket to create"
  type        = string
}
