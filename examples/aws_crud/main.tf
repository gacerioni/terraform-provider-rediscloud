terraform {
  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "1.0.1"
    }
  }
}

provider "rediscloud" {}

data "rediscloud_payment_method" "card" {
  card_type = "Visa"
}

resource "rediscloud_active_active_subscription" "demo" {
  name              = "aws_crud_demo"
  payment_method_id = data.rediscloud_payment_method.card.id
  cloud_provider    = "AWS"

  creation_plan {
    memory_limit_in_gb = 1
    quantity           = 1

    region {
      region                      = "us-east-1"
      networking_deployment_cidr  = "10.0.1.0/24"
      write_operations_per_second = 1000
      read_operations_per_second  = 1000
    }

    region {
      region                      = "us-east-2"
      networking_deployment_cidr  = "10.0.2.0/24"
      write_operations_per_second = 1000
      read_operations_per_second  = 1000
    }
  }
}

resource "rediscloud_active_active_subscription_database" "demo" {
  subscription_id = rediscloud_active_active_subscription.demo.id
  name            = "demo-db"

  memory_limit_in_gb = 1
}

resource "rediscloud_active_active_subscription_regions" "demo" {
  subscription_id = rediscloud_active_active_subscription.demo.id

  region {
    region                     = "us-east-1"
    networking_deployment_cidr = "10.0.1.0/24"

    database {
      id                                = rediscloud_active_active_subscription_database.demo.db_id
      database_name                     = rediscloud_active_active_subscription_database.demo.name
      local_write_operations_per_second = 1000
      local_read_operations_per_second  = 1000
    }
  }

  region {
    region                     = "us-east-2"
    networking_deployment_cidr = "10.0.2.0/24"

    database {
      id                                = rediscloud_active_active_subscription_database.demo.db_id
      database_name                     = rediscloud_active_active_subscription_database.demo.name
      local_write_operations_per_second = 1000
      local_read_operations_per_second  = 1000
    }
  }

  region {
    region                     = "eu-west-2"
    networking_deployment_cidr = "10.0.3.0/24"

    database {
      id                                = rediscloud_active_active_subscription_database.demo.db_id
      database_name                     = rediscloud_active_active_subscription_database.demo.name
      local_write_operations_per_second = 1000
      local_read_operations_per_second  = 1000
    }
  }
}
