terraform {
  required_version = ">= 1.8.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.164.0"
    }
  }
}

locals {
  name_prefix                 = "${var.project_name}-${var.environment}"
  managed_service_environment = var.environment == "prod" ? "PRODUCTION" : "PRESTABLE"
  release_channel             = var.environment == "prod" ? "STABLE" : "RAPID"

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    var.availability_zones[idx] => cidr
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    var.availability_zones[idx] => cidr
  }

  hostnames = {
    for app_env in var.app_environments :
    app_env => {
      auth     = app_env == "prod" ? "auth.${var.base_domain}" : "auth.${app_env}.${var.base_domain}"
      web      = app_env == "prod" ? "web.${var.base_domain}" : "web.${app_env}.${var.base_domain}"
      registry = app_env == "prod" ? "registry.${var.base_domain}" : "registry.${app_env}.${var.base_domain}"
      verify   = app_env == "prod" ? "verify.${var.base_domain}" : "verify.${app_env}.${var.base_domain}"
    }
  }

  postgresql_identities = merge(
    {
      for app_env in var.app_environments :
      "${app_env}-registry" => {
        app_env  = app_env
        service  = "registry"
        username = "diasoft_registry_${app_env}"
        database = "diasoft_registry_${app_env}"
      }
    },
    {
      for app_env in var.app_environments :
      "${app_env}-gateway" => {
        app_env  = app_env
        service  = "gateway"
        username = "diasoft_gateway_${app_env}"
        database = "diasoft_gateway_${app_env}"
      }
    },
    {
      for app_env in var.app_environments :
      "${app_env}-keycloak" => {
        app_env  = app_env
        service  = "keycloak"
        username = "diasoft_keycloak_${app_env}"
        database = "diasoft_keycloak_${app_env}"
      }
    },
  )

  kafka_topics = {
    "diploma.lifecycle.v1" = {
      partitions         = contains(var.app_environments, "prod") ? 12 : 3
      replication_factor = var.environment == "prod" ? min(3, length(var.availability_zones)) : 1
    }
    "sharelink.lifecycle.v1" = {
      partitions         = contains(var.app_environments, "prod") ? 6 : 3
      replication_factor = var.environment == "prod" ? min(3, length(var.availability_zones)) : 1
    }
    "gateway.dlq.v1" = {
      partitions         = 3
      replication_factor = var.environment == "prod" ? min(3, length(var.availability_zones)) : 1
    }
  }

  kafka_users = merge(
    {
      for app_env in var.app_environments :
      "${app_env}-registry" => {
        app_env = app_env
        name    = "diasoft-registry-${app_env}"
        permissions = [
          {
            topic_name = "diploma.lifecycle.v1"
            role       = "ACCESS_ROLE_PRODUCER"
          },
          {
            topic_name = "sharelink.lifecycle.v1"
            role       = "ACCESS_ROLE_PRODUCER"
          },
        ]
      }
    },
    {
      for app_env in var.app_environments :
      "${app_env}-gateway" => {
        app_env = app_env
        name    = "diasoft-gateway-${app_env}"
        permissions = [
          {
            topic_name = "diploma.lifecycle.v1"
            role       = "ACCESS_ROLE_CONSUMER"
          },
          {
            topic_name = "sharelink.lifecycle.v1"
            role       = "ACCESS_ROLE_CONSUMER"
          },
          {
            topic_name = "gateway.dlq.v1"
            role       = "ACCESS_ROLE_PRODUCER"
          },
          {
            topic_name = "gateway.dlq.v1"
            role       = "ACCESS_ROLE_CONSUMER"
          },
          {
            topic_name = "diploma.lifecycle.v1"
            role       = "ACCESS_ROLE_PRODUCER"
          },
          {
            topic_name = "sharelink.lifecycle.v1"
            role       = "ACCESS_ROLE_PRODUCER"
          },
        ]
      }
    },
  )

  lockbox_secret_names = merge(
    {
      for app_env in var.app_environments :
      app_env => {
        gateway       = "diasoft-gateway-${app_env}"
        registry      = "diasoft-registry-${app_env}"
        keycloak      = "keycloak-${app_env}"
        keycloak_admin = "keycloak-admin-${app_env}"
      }
    }
  )

  postgres_host = sort([for host in yandex_mdb_postgresql_cluster.platform.host : host.fqdn])[0]
  redis_host    = sort([for host in yandex_mdb_redis_cluster.gateway.host : host.fqdn])[0]
  kafka_brokers = join(",", sort([for host in yandex_mdb_kafka_cluster.platform.host : "${host.name}:9092"]))

  object_storage_bucket_name = replace("${local.name_prefix}-diploma-imports", "_", "-")
  object_storage_endpoint    = "https://storage.yandexcloud.net"
}

resource "yandex_vpc_network" "platform" {
  name = "${local.name_prefix}-vpc"
}

resource "yandex_vpc_gateway" "nat" {
  name = "${local.name_prefix}-nat"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  network_id = yandex_vpc_network.platform.id
  name       = "${local.name_prefix}-private"

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "public" {
  for_each = local.public_subnets

  name           = "${local.name_prefix}-public-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.platform.id
  v4_cidr_blocks = [each.value]
}

resource "yandex_vpc_subnet" "private" {
  for_each = local.private_subnets

  name           = "${local.name_prefix}-private-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.platform.id
  route_table_id = yandex_vpc_route_table.private.id
  v4_cidr_blocks = [each.value]
}

resource "yandex_iam_service_account" "cluster" {
  name = "${local.name_prefix}-k8s-cluster"
}

resource "yandex_iam_service_account" "nodes" {
  name = "${local.name_prefix}-k8s-nodes"
}

resource "yandex_iam_service_account" "object_storage" {
  name = "${local.name_prefix}-object-storage"
}

resource "yandex_iam_service_account" "external_secrets" {
  name = "${local.name_prefix}-external-secrets"
}

resource "yandex_iam_service_account" "external_dns" {
  name = "${local.name_prefix}-external-dns"
}

resource "yandex_resourcemanager_folder_iam_member" "cluster_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.cluster.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "nodes_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "object_storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.object_storage.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "external_secrets_lockbox_viewer" {
  folder_id = var.folder_id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.external_secrets.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "external_dns_editor" {
  folder_id = var.folder_id
  role      = "dns.editor"
  member    = "serviceAccount:${yandex_iam_service_account.external_dns.id}"
}

resource "yandex_iam_service_account_key" "external_secrets" {
  service_account_id = yandex_iam_service_account.external_secrets.id
  description        = "external-secrets bootstrap key for ${var.environment}"
}

resource "yandex_iam_service_account_key" "external_dns" {
  service_account_id = yandex_iam_service_account.external_dns.id
  description        = "external-dns bootstrap key for ${var.environment}"
}

resource "yandex_iam_service_account_static_access_key" "object_storage" {
  service_account_id = yandex_iam_service_account.object_storage.id
  description        = "object storage key for ${var.environment}"
}

resource "yandex_kubernetes_cluster" "platform" {
  name       = "${local.name_prefix}-k8s"
  network_id = yandex_vpc_network.platform.id

  master {
    regional {
      region = var.region

      dynamic "location" {
        for_each = yandex_vpc_subnet.private
        content {
          zone      = location.value.zone
          subnet_id = location.value.id
        }
      }
    }

    version   = var.kubernetes_version
    public_ip = false

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "sunday"
        start_time = "02:00"
        duration   = "4h"
      }
    }

    master_logging {
      enabled                    = true
      folder_id                  = var.folder_id
      kube_apiserver_enabled     = true
      cluster_autoscaler_enabled = true
      events_enabled             = true
      audit_enabled              = true
    }
  }

  service_account_id      = yandex_iam_service_account.cluster.id
  node_service_account_id = yandex_iam_service_account.nodes.id
  release_channel         = local.release_channel
  network_policy_provider = "CALICO"

  workload_identity_federation {
    enabled = true
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.cluster_editor,
    yandex_resourcemanager_folder_iam_member.nodes_editor,
  ]
}

resource "yandex_kubernetes_node_group" "platform" {
  cluster_id = yandex_kubernetes_cluster.platform.id
  name       = "${local.name_prefix}-system"
  version    = var.kubernetes_version

  instance_template {
    platform_id = var.node_platform_id

    resources {
      cores  = var.node_group_cores
      memory = var.node_group_memory_gb
    }

    boot_disk {
      type = var.node_group_disk_type
      size = var.node_group_disk_size_gb
    }

    network_interface {
      nat        = false
      subnet_ids = values(yandex_vpc_subnet.private)[*].id
    }

    container_runtime {
      type = "containerd"
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_group_size
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = yandex_vpc_subnet.private
      content {
        zone = location.value.zone
      }
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}

resource "random_password" "postgresql" {
  for_each = local.postgresql_identities

  length           = 32
  special          = true
  override_special = "_%@"
}

resource "yandex_mdb_postgresql_cluster" "platform" {
  name                = "${local.name_prefix}-postgresql"
  environment         = local.managed_service_environment
  network_id          = yandex_vpc_network.platform.id
  deletion_protection = var.environment == "prod"

  config {
    version = var.postgresql_version

    resources {
      resource_preset_id = var.postgresql_resource_preset_id
      disk_type_id       = var.postgresql_disk_type_id
      disk_size          = var.postgresql_disk_size_gb
    }
  }

  dynamic "host" {
    for_each = yandex_vpc_subnet.private
    content {
      zone             = host.value.zone
      subnet_id        = host.value.id
      assign_public_ip = false
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = 3
  }
}

resource "yandex_mdb_postgresql_user" "platform" {
  for_each = local.postgresql_identities

  cluster_id = yandex_mdb_postgresql_cluster.platform.id
  name       = each.value.username
  password   = random_password.postgresql[each.key].result
}

resource "yandex_mdb_postgresql_database" "platform" {
  for_each = local.postgresql_identities

  cluster_id  = yandex_mdb_postgresql_cluster.platform.id
  name        = each.value.database
  owner       = yandex_mdb_postgresql_user.platform[each.key].name
  lc_collate  = "en_US.UTF-8"
  lc_type     = "en_US.UTF-8"
  extension {
    name = "uuid-ossp"
  }
}

resource "random_password" "redis" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "yandex_mdb_redis_cluster" "gateway" {
  name                = "${local.name_prefix}-redis"
  environment         = local.managed_service_environment
  network_id          = yandex_vpc_network.platform.id
  deletion_protection = var.environment == "prod"
  announce_hostnames  = true

  config {
    password = random_password.redis.result
    version  = var.redis_version
  }

  resources {
    resource_preset_id = var.redis_resource_preset_id
    disk_size          = var.redis_disk_size_gb
  }

  dynamic "host" {
    for_each = yandex_vpc_subnet.private
    content {
      zone      = host.value.zone
      subnet_id = host.value.id
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 2
  }
}

resource "random_password" "kafka" {
  for_each = local.kafka_users

  length           = 32
  special          = true
  override_special = "_%@"
}

resource "yandex_mdb_kafka_cluster" "platform" {
  name                = "${local.name_prefix}-kafka"
  environment         = local.managed_service_environment
  network_id          = yandex_vpc_network.platform.id
  subnet_ids          = values(yandex_vpc_subnet.private)[*].id
  deletion_protection = var.environment == "prod"

  config {
    version          = var.kafka_version
    brokers_count    = var.environment == "prod" ? 1 : 1
    zones            = var.availability_zones
    assign_public_ip = false
    schema_registry  = false

    kafka {
      resources {
        resource_preset_id = var.kafka_resource_preset_id
        disk_type_id       = var.kafka_disk_type_id
        disk_size          = var.kafka_disk_size_gb
      }

      kafka_config {
        auto_create_topics_enable = false
        num_partitions            = tostring(local.kafka_topics["diploma.lifecycle.v1"].partitions)
        default_replication_factor = tostring(
          var.environment == "prod" ? min(3, length(var.availability_zones)) : 1
        )
        offsets_retention_minutes = "10080"
        sasl_enabled_mechanisms   = ["SASL_MECHANISM_SCRAM_SHA_512"]
      }
    }

    zookeeper {
      resources {
        resource_preset_id = var.kafka_zookeeper_resource_preset_id
        disk_type_id       = var.kafka_disk_type_id
        disk_size          = var.kafka_zookeeper_disk_size_gb
      }
    }
  }

  dynamic "topic" {
    for_each = local.kafka_topics
    content {
      name               = topic.key
      partitions         = topic.value.partitions
      replication_factor = topic.value.replication_factor
    }
  }

  dynamic "user" {
    for_each = local.kafka_users
    content {
      name     = user.value.name
      password = random_password.kafka[user.key].result

      dynamic "permission" {
        for_each = user.value.permissions
        content {
          topic_name = permission.value.topic_name
          role       = permission.value.role
        }
      }
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = 1
  }
}

resource "yandex_storage_bucket" "imports" {
  bucket     = local.object_storage_bucket_name
  access_key = yandex_iam_service_account_static_access_key.object_storage.access_key
  secret_key = yandex_iam_service_account_static_access_key.object_storage.secret_key

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
}

resource "random_password" "keycloak_admin" {
  for_each = toset(var.app_environments)

  length           = 24
  special          = true
  override_special = "_%@"
}

resource "yandex_lockbox_secret" "gateway" {
  for_each = toset(var.app_environments)
  name     = "diasoft-gateway-${each.key}"
}

resource "yandex_lockbox_secret" "registry" {
  for_each = toset(var.app_environments)
  name     = "diasoft-registry-${each.key}"
}

resource "yandex_lockbox_secret" "keycloak" {
  for_each = toset(var.app_environments)
  name     = "keycloak-${each.key}"
}

resource "yandex_lockbox_secret" "keycloak_admin" {
  for_each = toset(var.app_environments)
  name     = "keycloak-admin-${each.key}"
}

resource "yandex_lockbox_secret_version" "gateway" {
  for_each  = toset(var.app_environments)
  secret_id = yandex_lockbox_secret.gateway[each.key].id

  entries {
    key        = "database_url"
    text_value = "postgres://${
      yandex_mdb_postgresql_user.platform["${each.key}-gateway"].name
    }:${
      random_password.postgresql["${each.key}-gateway"].result
    }@${local.postgres_host}:6432/${
      yandex_mdb_postgresql_database.platform["${each.key}-gateway"].name
    }?sslmode=disable"
  }

  entries {
    key        = "redis_addr"
    text_value = "${local.redis_host}:6379"
  }

  entries {
    key        = "redis_password"
    text_value = random_password.redis.result
  }

  entries {
    key        = "kafka_brokers"
    text_value = local.kafka_brokers
  }

  entries {
    key        = "kafka_username"
    text_value = local.kafka_users["${each.key}-gateway"].name
  }

  entries {
    key        = "kafka_password"
    text_value = random_password.kafka["${each.key}-gateway"].result
  }
}

resource "yandex_lockbox_secret_version" "registry" {
  for_each  = toset(var.app_environments)
  secret_id = yandex_lockbox_secret.registry[each.key].id

  entries {
    key        = "database_url"
    text_value = "jdbc:postgresql://${local.postgres_host}:6432/${yandex_mdb_postgresql_database.platform["${each.key}-registry"].name}"
  }

  entries {
    key        = "database_username"
    text_value = yandex_mdb_postgresql_user.platform["${each.key}-registry"].name
  }

  entries {
    key        = "database_password"
    text_value = random_password.postgresql["${each.key}-registry"].result
  }

  entries {
    key        = "kafka_bootstrap_servers"
    text_value = local.kafka_brokers
  }

  entries {
    key        = "kafka_username"
    text_value = local.kafka_users["${each.key}-registry"].name
  }

  entries {
    key        = "kafka_password"
    text_value = random_password.kafka["${each.key}-registry"].result
  }

  entries {
    key        = "object_storage_access_key"
    text_value = yandex_iam_service_account_static_access_key.object_storage.access_key
  }

  entries {
    key        = "object_storage_secret_key"
    text_value = yandex_iam_service_account_static_access_key.object_storage.secret_key
  }
}

resource "yandex_lockbox_secret_version" "keycloak" {
  for_each  = toset(var.app_environments)
  secret_id = yandex_lockbox_secret.keycloak[each.key].id

  entries {
    key        = "db_host"
    text_value = local.postgres_host
  }

  entries {
    key        = "db_port"
    text_value = "6432"
  }

  entries {
    key        = "db_username"
    text_value = yandex_mdb_postgresql_user.platform["${each.key}-keycloak"].name
  }

  entries {
    key        = "db_password"
    text_value = random_password.postgresql["${each.key}-keycloak"].result
  }
}

resource "yandex_lockbox_secret_version" "keycloak_admin" {
  for_each  = toset(var.app_environments)
  secret_id = yandex_lockbox_secret.keycloak_admin[each.key].id

  entries {
    key        = "username"
    text_value = "admin"
  }

  entries {
    key        = "password"
    text_value = random_password.keycloak_admin[each.key].result
  }
}
