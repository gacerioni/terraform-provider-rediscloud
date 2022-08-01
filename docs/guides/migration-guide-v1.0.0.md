---
page_title: "Migrating to version v1.X.X"
subcategory: "Guides"
---

# Migrating to version v1.X.X

This guide is for the users who want to migrate their old Terraform configurations to `v1.X.X`.

The migration is safe, simple and will not alter any existing resources in your infrastructure.
The process is as follows:

## Why would I want to migrate?
The new version allows greater control over the database resource. It provides easier access to the attributes of the database, importing specific databases to the TF state file, and simpler database management.
All of these make the provider resources more stable and better for TF provisioning.   

The changes, such as new database resource extraction, can be found in the Terraform RedisCloud Provider CHANGELOG.

## Prerequisites

* The RedisCloud provider `>= 1.0.0`.
* Backup Terraform configuration file (.tf) and State file (.tfstate)
* Create an empty state file (.tfstate). You can create a new directory with your Terraform configuration files (.tf).

## Run migration

1. Update your HCL files to use the latest version of the schemas for your subscription and database resources.
The ‘database’ block has been extracted from the `rediscloud_subscription` to a new resource called ‘rediscloud_subscription_database’. In addition, a new block called `creation_plan` has been introduced to the ‘rediscloud_subscription’. So, to migrate to the new version, all you need to do is to modify your existing `rediscloud_subscription` schema and create a new resource called `rediscloud_subscription_database` for each of your databases in the subscription.

~> **Note:** If you want to create a new subscription, then the `creation_plan` block is required.

Here is an example of an old Terraform configuration:

```hcl
terraform {
  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "0.3.0"
    }
  }
}

data "rediscloud_payment_method" "card" {
  card_type = "Visa"
}

// This resource needs to be updated to the new schema
resource "rediscloud_subscription" "example" {

  name              = "example"
  payment_method    = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage    = "ram"

  cloud_provider { ... }

  // This block will be migrated to a separate resource
  database {
    name                         = "tf-example-database"
    protocol                     = "redis"
    memory_limit_in_gb           = 1
    data_persistence             = "none"
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 10000
    password                     = "encrypted-password-0"

    alert {
      name  = "dataset-size"
      value = 40
    }
  }
}
```

To use the latest schema, you need to modify the `rediscloud_subscription` resource and add a new `rediscloud_subscription_database` resources for your databases. Like so:

* New configuration (>= `1.0.0`):

  ```hcl
  terraform {
    required_providers {
      rediscloud = {
        source  = "RedisLabs/rediscloud"
        version = "1.0.0"
      }
    }
  }

  data "rediscloud_payment_method" "card" {
    card_type = "Visa"
  }
  
  resource "rediscloud_subscription" "example" {
    name = "example"
    memory_storage = "ram"
    payment_method_id = data.rediscloud_payment_method.card.id
  
    cloud_provider {...}
  
   	 // For migrating, you can skip this block,
	// However, if you would like to modify a field that requires a re-creation of the subscription, the creation_plan will be asked. 
    	// In this block, define your average database specification for your databases in the subscription. 
    creation_plan {
      average_item_size_in_bytes = 1
      memory_limit_in_gb = 1
      quantity = 1
      replication=false
      support_oss_cluster_api=false
      throughput_measurement_by = "operations-per-second"
      throughput_measurement_value = 10000
      modules = ["RedisJSON", "RedisBloom"]
    }
  }

  // The database block has been extracted to a separate resource - ‘rediscloud_subscription_database’.
  // The database attributes are the same as the ones in the previous database block in the old ‘redislcoud_subscription’ schema. 
  // With the exception of the new `subscription_id` attribute.
  resource "rediscloud_database" "first_database" {
      // Attach the database to the subscription.
      subscription_id = rediscloud_subscription.example.id
      name = "tf-example-database"
      protocol = "redis"
      memory_limit_in_gb = 1
      data_persistence = "none"
      throughput_measurement_by = "operations-per-second"
      throughput_measurement_value = 10000
      password = "encrypted-password-0"
  
      alert {
        name = "dataset-size"
        value = 40
      }
  }
  ```

2. Create a new directory with your new Terraform configuration files.
3. Run `terraform init` to initialize the new directory.
4. Run the following commands to import the resources into the state file:
    ```bash
    # Import the subscription resource
    terraform import rediscloud_subscription.example <subscription id>;
    # Import the database resource. The last argument contains the subscription id and the database id separated by a slash.
    terraform import rediscloud_database.first_database <subscription id>/<first database id>;
    terraform import rediscloud_database.second_database <subscription id>/<second database id>;

    ```
   **OPTIONAL**: If you have other resources like `rediscloud_cloud_account` or `rediscloud_subscription_peering`, then
   you will need to import them as well:
     ```bash
     # Import rediscloud_cloud_account
     terraform import rediscloud_cloud_account.cloud_example <cloud account id>;
     # Import the peering resource. The last argument contains the subscription id and the peering id separated by a slash.
     terraform import rediscloud_subscription_peering.peering_example <subscription_id>/<cloud account id>;
     ```


5. Verify that the new state file is valid:
    ```bash
    # List the resources in the state file
    terraform state list;
    # Check if the resources are valid
    terraform state show rediscloud_subscription.example;
    terraform state show rediscloud_database.first_database;
    terraform state show rediscloud_database.second_database;

    ```
   **OPTIONAL**: If you have other resources like `rediscloud_cloud_account` or `rediscloud_subscription_peering`, then
   you can check if they are valid:
     ```bash
     # Check if the cloud account resource is valid
     terraform state show rediscloud_cloud_account.cloud_example;
     # Check if the peering resource is valid
     terraform state show rediscloud_subscription_peering.peering_example;
     ```
   
Finally, run `terraform plan` to verify that your new configuration matches the real infrastructure.
Should receive a ‘no changes’ message back from the TF CLI. 

Congratulations! You have successfully migrated your Terraform configuration to the new schema.