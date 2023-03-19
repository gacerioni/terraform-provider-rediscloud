---
layout: "rediscloud"
page_title: "Redis Cloud: rediscloud_active_active_subscription_database"
description: |-
Database resource for Active-Active Subscriptions in the Terraform provider Redis Cloud.
---

# Resource: rediscloud_active_active_subscription_database

Creates a Database within a specified Active-Active Subscription in your Redis Enterprise Cloud Account.

## Example Usage

```hcl
data "rediscloud_payment_method" "card" {
	card_type = "Visa"
}

resource "rediscloud_active_active_subscription" "subscription-resource" {
  name = "subscription-name"
  payment_method_id = data.rediscloud_payment_method.card.id 
  cloud_provider = "AWS"

  creation_plan {
    memory_limit_in_gb = 1
    quantity = 1
	region {
		region = "us-east-1"
		networking_deployment_cidr = "192.168.0.0/24"
		write_operations_per_second = 1000
		read_operations_per_second = 1000
	}
	region {
		region = "us-east-2"
		networking_deployment_cidr = "10.0.1.0/24"
		write_operations_per_second = 1000
		read_operations_per_second = 2000
	}
  }
}

resource "rediscloud_active_active_subscription_database" "database-resource" {
    subscription_id = rediscloud_active_active_subscription.subscription-resource.id
    name = "database-name"
    memory_limit_in_gb = 1
    global_data_persistence = "aof-every-1-second"
    global_password = "some-random-pass-2" 
    global_source_ips = ["192.168.0.0/16"]
    global_alert {
	name = "dataset-size"
	value = 40
    }

    override_region {
    	name = "us-east-2"
        override_global_source_ips = ["192.10.0.0/16"]
    }

    override_region {
    	name = "us-east-1"
    	override_global_data_persistence = "none"
    	override_global_password = "region-specific-password"
    	override_global_alert {
        	name = "dataset-size"
        	value = 60
    	}
   }
}

output "us-east-1-public-endpoints" {
  value = rediscloud_active_active_subscription_database.database-resource.public_endpoint.us-east-1
}

output "us-east-2-private-endpoints" {
  value = rediscloud_active_active_subscription_database.database-resource.private_endpoint.us-east-1
}
```

## Argument Reference

The following arguments are supported:
* `subscription_id`: (Required) The ID of the Active-Active subscription to create the database in
* `name` - (Required) A meaningful name to identify the database
* `memory_limit_in_gb` - (Required) Maximum memory usage for this specific database, including replication and other overhead
* `support_oss_cluster_api` - (Optional) Support Redis open-source (OSS) Cluster API. Default: ‘false’
* `external_endpoint_for_oss_cluster_api` - (Optional) Should use the external endpoint for open-source (OSS) Cluster API.
  Can only be enabled if OSS Cluster API support is enabled. Default: 'false'
* `enable_tls` - (Optional) Use TLS for authentication. Default: ‘false’
* `client_ssl_certificate` - (Optional) SSL certificate to authenticate user connections.
* `data_eviction` - (Optional) The data items eviction policy (either: 'allkeys-lru', 'allkeys-lfu', 'allkeys-random', 'volatile-lru', 'volatile-lfu', 'volatile-random', 'volatile-ttl' or 'noeviction'. Default: 'volatile-lru')
* `global_data_persistence` - (Optional) Global rate of database data persistence (in persistent storage) of regions that dont override global settings. Default: 'none'
* `global_password` - (Optional) Password to access the database of regions that dont override global settings. If left empty, the password will be generated automatically
* `global_alert` - (Optional) A block defining Redis database alert of regions that dont override global settings, documented below, can be specified multiple times
* `global_source_ips` - (Optional)  List of source IP addresses or subnet masks of regions that dont override global settings. If specified, Redis clients will be able to connect to this database only from within the specified source IP addresses ranges (example: ['192.168.10.0/32', '192.168.12.0/24'])
* `override_region` - (Optional) Override region specific configuration, documented below


The `override_region` block supports:

* `name` - (Required) Region name.
* `override_global_alert` - (Optional) A block defining Redis regional instance of an Active-Active database alert, documented below, can be specified multiple times
* `override_global_password` - (Optional) If specified, this regional instance of an Active-Active database password will be used to access the database
* `override_global_source_ips` - (Optional)  List of regional instance of an Active-Active database source IP addresses or subnet masks. If specified, Redis clients will be able to connect to this database only from within the specified source IP addresses ranges (example: ['192.168.10.0/32', '192.168.12.0/24'] )
* `override_global_data_persistence` - (Optional) Regional instance of an Active-Active database data persistence rate (in persistent storage)

The `override_global_alert` block supports:

* `name` - (Required) Alert name
* `value` - (Required) Alert value

### Timeouts

The `timeouts` block allows you to specify [timeouts](https://www.terraform.io/language/resources/syntax#operation-timeouts) for certain actions:

* `create` - (Defaults to 30 mins) Used when creating the database
* `update` - (Defaults to 30 mins) Used when updating the database
* `delete` - (Defaults to 10 mins) Used when destroying the database

## Attribute reference

* `db_id` - Identifier of the database created
* `public_endpoint` - A map of which public endpoints can to access the database per region, uses region name as key.
* `private_endpoint` - A map of which private endpoints can to access the database per region, uses region name as key.

## Import
`rediscloud_active_active_subscription_database` can be imported using the ID of the Active-Active subscription and the ID of the database in the format {subscription ID}/{database ID}, e.g.

```
$ terraform import rediscloud_active_active_subscription_database.database-resource 123456/12345678
```

Note: Due to constraints in the Redis Cloud API, the import process will not import global attributes or override region attributes. If you wish to use these attributes in your Terraform configuraton, you will need to manually add them to your Terraform configuration and run `terraform apply` to update the database.
