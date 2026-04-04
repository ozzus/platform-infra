variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_environments" {
  type = list(string)
}

variable "cloud_id" {
  type    = string
  default = "cloud-placeholder"
}

variable "folder_id" {
  type    = string
  default = "folder-placeholder"
}

variable "region" {
  type    = string
  default = "ru-central1"
}

variable "base_domain" {
  type    = string
  default = "example.com"
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "node_platform_id" {
  type    = string
  default = "standard-v3"
}

variable "node_group_size" {
  type    = number
  default = 3
}

variable "node_group_cores" {
  type    = number
  default = 4
}

variable "node_group_memory_gb" {
  type    = number
  default = 8
}

variable "node_group_disk_type" {
  type    = string
  default = "network-ssd"
}

variable "node_group_disk_size_gb" {
  type    = number
  default = 64
}

variable "postgresql_version" {
  type    = string
  default = "16"
}

variable "postgresql_resource_preset_id" {
  type    = string
  default = "b3-c4-m16"
}

variable "postgresql_disk_type_id" {
  type    = string
  default = "network-ssd"
}

variable "postgresql_disk_size_gb" {
  type    = number
  default = 40
}

variable "redis_version" {
  type    = string
  default = "7.2"
}

variable "redis_resource_preset_id" {
  type    = string
  default = "hm1.nano"
}

variable "redis_disk_size_gb" {
  type    = number
  default = 16
}

variable "kafka_version" {
  type    = string
  default = "3.6"
}

variable "kafka_resource_preset_id" {
  type    = string
  default = "s2.micro"
}

variable "kafka_zookeeper_resource_preset_id" {
  type    = string
  default = "s2.micro"
}

variable "kafka_disk_type_id" {
  type    = string
  default = "network-ssd"
}

variable "kafka_disk_size_gb" {
  type    = number
  default = 64
}

variable "kafka_zookeeper_disk_size_gb" {
  type    = number
  default = 20
}
