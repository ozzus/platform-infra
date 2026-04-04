output "infra_environment" {
  value = var.environment
}

output "app_environments" {
  value = var.app_environments
}

output "dns_hostnames" {
  value = local.hostnames
}

output "network" {
  value = {
    network_id          = yandex_vpc_network.platform.id
    public_subnet_ids   = { for zone, subnet in yandex_vpc_subnet.public : zone => subnet.id }
    private_subnet_ids  = { for zone, subnet in yandex_vpc_subnet.private : zone => subnet.id }
    private_route_table = yandex_vpc_route_table.private.id
    nat_gateway_id      = yandex_vpc_gateway.nat.id
  }
}

output "kubernetes" {
  value = {
    cluster_id    = yandex_kubernetes_cluster.platform.id
    cluster_name  = yandex_kubernetes_cluster.platform.name
    release       = local.release_channel
    node_group_id = yandex_kubernetes_node_group.platform.id
  }
}

output "service_accounts" {
  value = {
    cluster          = yandex_iam_service_account.cluster.id
    nodes            = yandex_iam_service_account.nodes.id
    object_storage   = yandex_iam_service_account.object_storage.id
    external_secrets = yandex_iam_service_account.external_secrets.id
    external_dns     = yandex_iam_service_account.external_dns.id
  }
}

output "managed_postgresql" {
  value = {
    cluster_id = yandex_mdb_postgresql_cluster.platform.id
    host       = local.postgres_host
    databases = {
      for key, identity in local.postgresql_identities :
      key => {
        username = identity.username
        database = identity.database
      }
    }
  }
}

output "managed_redis" {
  value = {
    cluster_id = yandex_mdb_redis_cluster.gateway.id
    host       = local.redis_host
  }
}

output "managed_kafka" {
  value = {
    cluster_id = yandex_mdb_kafka_cluster.platform.id
    brokers    = local.kafka_brokers
    topics     = keys(local.kafka_topics)
    users = {
      for key, user in local.kafka_users :
      key => user.name
    }
  }
}

output "object_storage" {
  value = {
    bucket   = yandex_storage_bucket.imports.bucket
    endpoint = local.object_storage_endpoint
  }
}

output "lockbox_secret_names" {
  value = {
    gateway = {
      for env in var.app_environments :
      env => yandex_lockbox_secret.gateway[env].name
    }
    registry = {
      for env in var.app_environments :
      env => yandex_lockbox_secret.registry[env].name
    }
    keycloak = {
      for env in var.app_environments :
      env => yandex_lockbox_secret.keycloak[env].name
    }
    keycloak_admin = {
      for env in var.app_environments :
      env => yandex_lockbox_secret.keycloak_admin[env].name
    }
  }
}

output "bootstrap_authorized_keys" {
  sensitive = true
  value = {
    external_secrets = jsonencode({
      id                 = yandex_iam_service_account_key.external_secrets.id
      service_account_id = yandex_iam_service_account.external_secrets.id
      private_key        = yandex_iam_service_account_key.external_secrets.private_key
      public_key         = yandex_iam_service_account_key.external_secrets.public_key
    })
    external_dns = jsonencode({
      id                 = yandex_iam_service_account_key.external_dns.id
      service_account_id = yandex_iam_service_account.external_dns.id
      private_key        = yandex_iam_service_account_key.external_dns.private_key
      public_key         = yandex_iam_service_account_key.external_dns.public_key
    })
  }
}
