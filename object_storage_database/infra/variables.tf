# provider and common variables
variable "yc_zone" {
  type        = string
  description = "Zone for Yandex Cloud resources"
}
variable "yc_token" {
  type        = string
  description = "Yandex Cloud OAuth token"
}

variable "yc_cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "yc_folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

# IAM variables
variable "yc_service_account_name"{
  type        = string
  description = "Name of the service account"
}

# network variables
variable "yc_network_name" {
  type        = string
  description = "Name of the network"
}

variable "yc_subnet_name" {
  type        = string
  description = "Name of the custom subnet"
}

variable "yc_subnet_range" {
  type        = string
  description = "CIDR block for the subnet"
}

# S3 variables
variable "yc_bucket_name" {
  type        = string
  description = "Name of the bucket"
}

variable "yc_bucket_size" {
  type        = number
  description = "Size of the bucket"
}

variable "yc_default_storage_class" {
  type        = string
  description = "Class of the bucket"
}

# DB variables
variable "yc_mysql_cluster_name" {
  type        = string
  description = "Name of the MySQL cluster"
}

variable "yc_mysql_version" {
  type        = string
  description = "Version of MySQL"
}

variable "yc_mysql_environment" {
  type        = string
  description = "Environment of MySQL"
}

variable "yc_mysql_database_name" {
  type        = string
  description = "Name of the MySQL database"
}

variable "yc_mysql_user_name" {
  type        = string
  description = "Name of the MySQL user"
}

variable "yc_mysql_user_password" {
  type        = string
  description = "Password of the MySQL user"
}

variable "yc_mysql_resource_preset_id" {
  type        = string
  description = "Resource preset for MySQL cluster"
  default     = "s2.micro"
}

variable "yc_mysql_disk_type_id" {
  type        = string
  description = "Disk type for MySQL cluster"
  default     = "network-ssd"
}

variable "yc_mysql_disk_size" {
  type        = number
  description = "Disk size for MySQL cluster in GB"
  default     = 30
}

variable "yc_mysql_config" {
  description = "MySQL configuation"
  type = object({
    sql_mode                      = string
    max_connections               = number
    default_authentication_plugin = string
    innodb_print_all_deadlocks    = bool
  })
  default = {
    sql_mode                      = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
    max_connections               = 100
    default_authentication_plugin = "MYSQL_NATIVE_PASSWORD"
    innodb_print_all_deadlocks    = true
  }
}
